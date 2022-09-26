local Config = require("noice.config")
local Util = require("noice.util")
local Object = require("nui.object")

---@alias NoiceRender fun(view: NoiceView)

---@alias NoiceViewOptions NoiceNuiOptions|{buf_options?: table<string,any>}

---@class NoiceView
---@field _tick number
---@field _messages NoiceMessage[]
---@field _opts? table
---@field _visible boolean
local View = Object("View")

function View.get_view(view, opts)
  opts = vim.tbl_deep_extend("force", Config.options.views[view] or {}, opts or {})
  opts.render = opts.render or view
  return View(opts.render, opts)
end

---@param opts? table
function View:init(render, opts)
  opts = opts or {}

  self._tick = 0
  self._messages = {}
  self._opts = opts or {}
  self._visible = true
  self._render = type(render) == "function" and render or require("noice.view." .. render)
  self._render = self._render(self)
  if type(self._render) ~= "function" then
    Util.error("Invalid view config " .. vim.inspect({ render = render, opts = opts }))
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

  if not dirty and not self._visible and #self._messages > 0 then
    -- FIXME:
    dirty = true
  end

  if dirty then
    self._messages = messages
    self._visible = #self._messages > 0
    Util.try(self._render, self)
    return true
  end
  return false
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

---@alias NoiceView.constructor fun(render: string|NoiceRender, opts?: table): NoiceView
---@type NoiceView|NoiceView.constructor
local NoiceView = View
return NoiceView
