local Config = require("noice.config")
local Util = require("noice.util")
local Object = require("nui.object")

---@alias NoiceViewOptions NoiceNuiOptions|{buf_options?: table<string,any>}

---@class NoiceView
---@field _tick number
---@field _messages NoiceMessage[]
---@field _opts? table
---@field _visible boolean
local View = Object("NoiceView")

function View.get_view(view, opts)
  opts = vim.tbl_deep_extend("force", Config.options.views[view] or {}, opts or {})
  ---@type NoiceView
  local class = Util.try(require, "noice.view." .. (opts.render or view))
  return class(opts)
end

---@param opts? NoiceViewOptions
function View:init(opts)
  self._tick = 0
  self._messages = {}
  self._opts = opts or {}
  self._visible = true
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
