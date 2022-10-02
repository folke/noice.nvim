local require = require("noice.util.lazy")

local Config = require("noice.config")
local Util = require("noice.util")
local Object = require("nui.object")
local Filter = require("noice.filter")
local Hacks = require("noice.hacks")

---@class NoiceViewBaseOptions
---@field buf_options? table<string,any>
---@field filter_options? { filter: NoiceFilter, opts: NoiceNuiOptions }[]
---@field render string
--
---@alias NoiceViewOptions NoiceViewBaseOptions|NoiceNuiOptions

---@class NoiceView
---@field _tick number
---@field _messages NoiceMessage[]
---@field _opts NoiceViewOptions
---@field _view_opts NoiceViewOptions
---@field _visible boolean
local View = Object("NoiceView")

---@param view string
---@param opts NoiceViewOptions
function View.get_view(view, opts)
  local view_options = Config.options.views[view] or {}
  opts = vim.tbl_deep_extend("force", view_options, opts or {})
  if view_options.filter_options then
    vim.list_extend(opts.filter_options, view_options.filter_options)
  end
  ---@type NoiceView
  local class = Util.try(require, "noice.view." .. (opts.render or view))
  return class(opts)
end

---@param opts? NoiceViewOptions
function View:init(opts)
  self._tick = 0
  self._messages = {}
  self._opts = opts or {}
  self._view_opts = vim.tbl_deep_extend("force", {}, self._opts)
  self._visible = true
end

function View:_calc_opts()
  local orig_opts = vim.tbl_deep_extend("force", {}, self._opts)
  self._opts = vim.tbl_deep_extend("force", {}, self._view_opts)
  if self._opts.filter_options then
    for _, fo in ipairs(self._opts.filter_options) do
      if Filter.has(self._messages, fo.filter) then
        self._opts = vim.tbl_deep_extend("force", self._opts, fo.opts or {})
      end
    end
  end
  if not vim.deep_equal(orig_opts, self._opts) then
    self:reset()
  end
end

---@param messages NoiceMessage[]
function View:display(messages)
  local dirty = #messages ~= #self._messages
  for _, m in ipairs(messages) do
    if m.tick > self._tick then
      self._tick = m.tick
      dirty = true
    end
  end

  if dirty then
    self._messages = messages
    if #self._messages > 0 then
      self:_calc_opts()

      Hacks.block_redraw = true
      Util.try(self.show, self)
      Hacks.block_redraw = false

      self._visible = true
    else
      self._visible = false
      self:hide()
    end
    return true
  end
  return false
end

function View:reset() end

function View:show()
  Util.error("Missing implementation `View:show()` for %s", self)
end

function View:hide()
  Util.error("Missing implementation `View:hide()` for %s", self)
end

function View:height()
  local ret = 0
  for _, m in ipairs(self._messages) do
    ret = ret + m:height()
  end
  return ret
end

function View:width()
  local ret = 0
  for _, m in ipairs(self._messages) do
    ret = math.max(ret, m:width())
  end
  return ret
end

function View:content()
  return table.concat(
    vim.tbl_map(
      ---@param m NoiceMessage
      function(m)
        return m:content()
      end,
      self._messages
    ),
    "\n"
  )
end

---@param buf number buffer number
---@param opts? {offset: number, highlight: boolean} line number (1-indexed), if `highlight`, then only highlight
function View:render(buf, opts)
  opts = opts or {}
  opts.offset = opts.offset or 1

  if self._opts.buf_options then
    require("nui.utils")._.set_buf_options(buf, self._opts.buf_options)
  end

  if not opts.highlight then
    vim.api.nvim_buf_set_lines(buf, opts.offset - 1, -1, false, {})
  end

  for _, m in ipairs(self._messages) do
    if opts.highlight then
      m:highlight(buf, Config.ns, opts.offset)
    else
      m:render(buf, Config.ns, opts.offset)
    end
    m:highlight_cursor(buf, Config.ns, opts.offset)
    opts.offset = opts.offset + m:height()
  end
end

---@alias NoiceView.constructor fun(opts?: NoiceViewOptions): NoiceView
---@type NoiceView|NoiceView.constructor
local NoiceView = View
return NoiceView
