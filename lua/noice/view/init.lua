local require = require("noice.util.lazy")

local Config = require("noice.config")
local Util = require("noice.util")
local Object = require("nui.object")
local Filter = require("noice.message.filter")
local Hacks = require("noice.util.hacks")

---@class NoiceViewBaseOptions
---@field buf_options? table<string,any>
---@field filter_options? { filter: NoiceFilter, opts: NoiceNuiOptions }[]
---@field backend string
---@field format? NoiceFormat
--
---@alias NoiceViewOptions NoiceViewBaseOptions|NoiceNuiOptions|NoiceNotifyOptions

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
  ---@diagnostic disable-next-line: undefined-field
  local class = Util.try(require, "noice.view." .. (opts.backend or opts.render or view))
  opts.view = view
  return class(opts)
end

---@param opts? NoiceViewOptions
function View:init(opts)
  self._tick = 0
  self._messages = {}
  self._opts = opts or {}
  self._visible = true
  self._view_opts = vim.deepcopy(self._opts)
  self:update_options()
end

function View:update_options() end

---@param messages NoiceMessage[]
function View:check_options(messages)
  ---@type NoiceViewOptions
  local old = vim.deepcopy(self._opts)
  self._opts = vim.deepcopy(self._view_opts)
  for _, fo in ipairs(self._opts.filter_options or {}) do
    if Filter.has(messages, fo.filter) then
      self._opts = vim.tbl_deep_extend("force", self._opts, fo.opts or {})
    end
  end
  self:update_options()
  if not vim.deep_equal(old, self._opts) then
    self:reset(old, self._opts)
  end
end

---@param messages NoiceMessage[]
---@param opts? {dirty?:boolean, format?: boolean}
function View:display(messages, opts)
  opts = opts or {}
  local dirty = (#messages ~= #self._messages) or opts.dirty
  for _, m in ipairs(messages) do
    if m.tick > self._tick then
      self._tick = m.tick
      dirty = true
    end
  end

  if dirty then
    if opts.format == false then
      self._messages = messages
    else
      self:format(messages)
    end
    if #self._messages > 0 then
      self:check_options(messages)

      Util.try(self.show, self)

      self._visible = true
    else
      self._visible = false
      self:hide()
    end
    return true
  end
  return false
end

---@param messages NoiceMessage[]
function View:format(messages)
  self._messages = vim.tbl_map(
    ---@param message NoiceMessage
    function(message)
      return require("noice.text.format").format(message, self._opts.format)
    end,
    messages
  )
end

---@param old NoiceViewOptions
---@param new NoiceViewOptions
function View:reset(old, new) end

function View:show()
  Util.error("Missing implementation `View:show()` for %s", self)
end

function View:hide()
  Util.error("Missing implementation `View:hide()` for %s", self)
end

---@param messages? NoiceMessage[]
function View:height(messages)
  local ret = 0
  for _, m in ipairs(messages or self._messages) do
    ret = ret + m:height()
  end
  return ret
end

---@param messages? NoiceMessage[]
function View:width(messages)
  local ret = 0
  for _, m in ipairs(messages or self._messages) do
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
---@param opts? {offset: number, highlight: boolean, messages?: NoiceMessage[]} line number (1-indexed), if `highlight`, then only highlight
function View:render(buf, opts)
  opts = opts or {}
  local linenr = opts.offset or 1

  if self._opts.buf_options then
    require("nui.utils")._.set_buf_options(buf, self._opts.buf_options)
  end

  if not opts.highlight then
    vim.api.nvim_buf_set_lines(buf, linenr - 1, -1, false, {})
  end

  for _, m in ipairs(opts.messages or self._messages) do
    if opts.highlight then
      m:highlight(buf, Config.ns, linenr)
    else
      m:render(buf, Config.ns, linenr)
    end
    linenr = linenr + m:height()
  end
end

---@alias NoiceView.constructor fun(opts?: NoiceViewOptions): NoiceView
---@return NoiceView|NoiceView.constructor
return View
