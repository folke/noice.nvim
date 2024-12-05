local require = require("noice.util.lazy")

local Util = require("noice.util")
local _ = require("nui.utils")._

local M = {}

M.transparent = false

local function check_bg()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  M.transparent = not (normal and normal.bg ~= nil)
end
check_bg()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("noice_transparent", { clear = true }),
  callback = check_bg,
})

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
  if opts.win_options and opts.win_options.winblend and M.transparent then
    opts.win_options.winblend = 0
  end
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

  if Util.islist(opts.padding) then
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
    if opts.relative == "editor" or type(opts.relative) == "table" and opts.relative.type == "editor" then
      size.max_width = size.max_width or vim.o.columns - 4
      size.max_height = size.max_height or vim.o.lines - 4
    end
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
  Util.wo(win, { scrolloff = 0 })
  local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
  local height = vim.api.nvim_win_get_height(win)
  local top = view.topline
  top = top + delta
  top = math.max(top, 1)
  top = math.min(top, M.win_buf_height(win) - height + 1)

  vim.defer_fn(function()
    vim.api.nvim_win_call(win, function()
      vim.fn.winrestview({ topline = top, lnum = top })
    end)
  end, 0)
end

return M
