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
  local b1 = M.bounds(win1)
  local b2 = M.bounds(win2)

  if b2.xmin > b1.xmax or b1.xmin > b2.xmax then
    return false
  end
  if b2.ymin > b1.ymax or b1.ymin > b2.ymax then
    return false
  end
  return true
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
  if opts.border and opts.border.style == "none" then
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
    elseif #opts.padding == 2 then
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

---@param opts? _.NuiBorder
---@return _.NuiBorderPadding
function M.get_border_size(opts)
  opts = opts or {}

  local border_size = opts.style and opts.style ~= "none" and 1 or 0
  local padding = M.normalize_padding(opts)

  return {
    top = border_size + padding.top,
    bottom = border_size + padding.bottom,
    right = border_size + padding.right,
    left = border_size + padding.left,
  }
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
    if position and not (opts.relative and opts.relative.type == "cursor") then
      if type(position.col) == "number" and position.col < 0 then
        position.col = vim.o.columns + position.col - dim.width
      end
      if type(position.row) == "number" and position.row < 0 then
        position.row = vim.o.lines + position.row - dim.height
      end
    end
    if size.width == "auto" then
      size.width = minmax(size.min_width, size.max_width, dim.width)
    end
    if size.height == "auto" then
      size.height = minmax(size.min_height, size.max_height, dim.height)
    end
  end

  return { size = size, position = position, relative = opts.relative }
end

return M
