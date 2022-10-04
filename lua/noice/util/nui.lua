local require = require("noice.util.lazy")

local Util = require("noice.util")

local M = {}

---@param opts NoiceViewOptions
function M.fix(opts)
  if type(opts.border) == "table" and opts.border.style == "none" then
    opts.border.text = nil
  end

  if opts.win_options and opts.win_options.winhighlight then
    opts.win_options.winhighlight = Util.nui.get_win_highlight(opts.win_options.winhighlight)
  end
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

---@param dim {width: number, height:number}
---@param opts NoiceViewOptions
---@return NoiceNuiOptions
function M.get_layout(dim, opts)
  local position = vim.deepcopy(opts.position)
  local size = vim.deepcopy(opts.size)

  ---@return number
  local function minmax(min, max, value)
    return math.max(min or 1, math.min(value, max or 1000))
  end

  if size and opts.type == "popup" then
    if size == "auto" then
      size = { height = "auto", width = "auto" }
    end
    if size.width == "auto" then
      size.width = minmax(size.min_width, size.max_width, dim.width)
    end
    if size.height == "auto" then
      size.height = minmax(size.min_height, size.max_height, dim.height)
    end
  end

  if size and opts.type == "split" then
    if size == "auto" then
      if position == "top" or position == "bottom" then
        size = minmax(opts.min_size, opts.max_size, dim.height)
      else
        size = minmax(opts.min_size, opts.max_size, dim.width)
      end
    end
  end
  return { size = size, position = position, relative = opts.relative }
end

return M
