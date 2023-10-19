local require = require("noice.util.lazy")

local Util = require("noice.util")
local _ = require("nui.utils")._

local M = {}

---@param opts? NoiceNuiOptions
---@return _.NoiceNuiOptions
function M.normalize(opts)
  opts = opts or {}

  M.normalize_win_options(opts)

  if opts.type == "split" then
    ---@cast opts NuiSplitOptions
    return M.normalize_split_options(opts)
  elseif opts.type == "popup" then
    ---@cast opts NuiPopupOptions
    return M.normalize_popup_options(opts)
  end
  error("Missing type for " .. vim.inspect(opts))
end

---@param opts? NoiceNuiOptions
function M.normalize_win_options(opts)
  opts = opts or {}
  if opts.win_options and opts.win_options.winhighlight then
    opts.win_options.winhighlight = Util.nui.get_win_highlight(opts.win_options.winhighlight)
  end
end

---@return {xmin:integer, xmax:integer, ymin:integer, ymax:integer}
function M.bounds(win)
  local pos = vim.api.nvim_win_get_position(win)
  local height = vim.api.nvim_win_get_height(win)
  local width = vim.api.nvim_win_get_width(win)
  return {
    xmin = pos[2],
    xmax = pos[2] + width,
    ymin = pos[1],
    ymax = pos[1] + height,
  }
end

function M.overlap(win1, win2)
  local bb1 = M.bounds(win1)
  local bb2 = M.bounds(win2)

  -- # determine the coordinates of the intersection rectangle
  local x_left = math.max(bb1["xmin"], bb2["xmin"])
  local y_top = math.max(bb1["ymin"], bb2["ymin"])
  local x_right = math.min(bb1["xmax"], bb2["xmax"])
  local y_bottom = math.min(bb1["ymax"], bb2["ymax"])

  if x_right < x_left or y_bottom < y_top then
    return 0.0
  end

  -- # The intersection of two axis-aligned bounding boxes is always an
  -- # axis-aligned bounding box
  local intersection_area = math.max(x_right - x_left, 1) * math.max(y_bottom - y_top, 1)

  -- # compute the area of both AABBs
  local bb1_area = (bb1["xmax"] - bb1["xmin"]) * (bb1["ymax"] - bb1["ymin"])
  local bb2_area = (bb2["xmax"] - bb2["xmin"]) * (bb2["ymax"] - bb2["ymin"])

  -- # compute the intersection over union by taking the intersection
  -- # area and dividing it by the sum of prediction + ground-truth
  -- # areas - the interesection area
  return intersection_area / (bb1_area + bb2_area - intersection_area)
end

---@param opts? NuiPopupOptions
---@return _.NuiPopupOptions
function M.normalize_popup_options(opts)
  opts = vim.deepcopy(opts or {})

  -- relative, position, size
  _.normalize_layout_options(opts)

  -- border
  local border = opts.border
  if type(border) == "string" then
    opts.border = { style = border }
  end

  -- border padding
  if opts.border then
    opts.border.padding = M.normalize_padding(opts.border)
  end

  -- fix border text
  if opts.border and (not opts.border.style or opts.border.style == "none" or opts.border.style == "shadow") then
    opts.border.text = nil
  end
  return opts
end

---@param opts? NuiSplitOptions
---@return _.NuiSplitOptions
function M.normalize_split_options(opts)
  opts = vim.deepcopy(opts or {})

  -- relative
  require("nui.split.utils").normalize_options(opts)

  return opts
end

---@param hl string|table<string,string>
function M.get_win_highlight(hl)
  if type(hl) == "string" then
    return hl
  end
  local ret = {}
  for key, value in pairs(hl) do
    table.insert(ret, key .. ":" .. value)
  end
  return table.concat(ret, ",")
end

---@param opts? NuiBorder|_.NuiBorderStyle|_.NuiBorder
---@return _.NuiBorderPadding
function M.normalize_padding(opts)
  opts = opts or {}
  if type(opts) == "string" then
    opts = { style = opts }
  end

  if vim.tbl_islist(opts.padding) then
    if #opts.padding == 2 then
      return {
        top = opts.padding[1],
        bottom = opts.padding[1],
        left = opts.padding[2],
        right = opts.padding[2],
      }
    elseif #opts.padding == 4 then
      return {
        top = opts.padding[1],
        right = opts.padding[2],
        bottom = opts.padding[3],
        left = opts.padding[4],
      }
    end
  end
  return vim.tbl_deep_extend("force", {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  }, opts.padding or {})
end

function M.win_buf_height(win)
  local buf = vim.api.nvim_win_get_buf(win)

  if not vim.wo[win].wrap then
    return vim.api.nvim_buf_line_count(buf)
  end

  local width = vim.api.nvim_win_get_width(win)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local height = 0
  for _, l in ipairs(lines) do
    height = height + math.max(1, (math.ceil(vim.fn.strwidth(l) / width)))
  end
  return height
end

---@param dim {width: number, height:number}
---@param _opts NoiceNuiOptions
---@return _.NoiceNuiOptions
function M.get_layout(dim, _opts)
  ---@type _.NoiceNuiOptions
  local opts = M.normalize(_opts)

  local position = vim.deepcopy(opts.position)
  local size = vim.deepcopy(opts.size)

  ---@return number
  local function minmax(min, max, value)
    return math.max(min or 1, math.min(value, max or 1000))
  end

  if opts.type == "split" then
    ---@cast opts _.NuiSplitOptions
    if size == "auto" then
      if position == "top" or position == "bottom" then
        size = minmax(opts.min_size, opts.max_size, dim.height)
      else
        size = minmax(opts.min_size, opts.max_size, dim.width)
      end
    end
  elseif opts.type == "popup" then
    if size.width == "auto" then
      size.width = minmax(size.min_width, size.max_width, dim.width)
      dim.width = size.width
    end
    if size.height == "auto" then
      size.height = minmax(size.min_height, size.max_height, dim.height)
      dim.height = size.height
    end
    if position and not (opts.relative and opts.relative.type == "cursor") then
      if type(position.col) == "number" and position.col < 0 then
        position.col = vim.o.columns + position.col - dim.width
      end
      if type(position.row) == "number" and position.row < 0 then
        position.row = vim.o.lines + position.row - dim.height
      end
    end
  end

  return { size = size, position = position, relative = opts.relative }
end

function M.anchor(width, height)
  local anchor = ""
  local lines_above = vim.fn.screenrow() - 1
  local lines_below = vim.fn.winheight(0) - lines_above

  if height < lines_below then
    anchor = anchor .. "N"
  else
    anchor = anchor .. "S"
  end

  if vim.go.columns - vim.fn.screencol() > width then
    anchor = anchor .. "W"
  else
    anchor = anchor .. "E"
  end
  return anchor
end

function M.scroll(win, delta)
  local info = vim.fn.getwininfo(win)[1] or {}
  local top = info.topline or 1
  local buf = vim.api.nvim_win_get_buf(win)
  top = top + delta
  top = math.max(top, 1)
  top = math.min(top, M.win_buf_height(win) - info.height + 1)

  vim.defer_fn(function()
    vim.api.nvim_buf_call(buf, function()
      vim.api.nvim_command("noautocmd silent! normal! " .. top .. "zt")
      vim.api.nvim_exec_autocmds("WinScrolled", { modeline = false })
    end)
  end, 0)
end

return M
