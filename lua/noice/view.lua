local Config = require("noice.config")
local Util = require("noice.util")
local Object = require("nui.object")

---@alias NoiceRender fun(view: NoiceView)

---@class NoiceView
---@field _render NoiceRender
---@field _tick number
---@field messages NoiceMessage[]
---@field opts? table
---@field visible boolean
local View = Object("View")

---@param render string|NoiceRender
---@param opts? table
function View:init(render, opts)
  self._render = type(render) == "function" and render or require("noice.render")[render]
  self._tick = 0
  self.messages = {}
  self.opts = opts or {}
  self.visible = true
end

---@param messages NoiceMessage[]
function View:display(messages)
  local dirty = #messages ~= #self.messages
  for _, m in ipairs(messages) do
    if m.tick > self._tick then
      self._tick = m.tick
      dirty = true
    end
  end

  if not dirty and not self.visible and #self.messages > 0 then
    -- FIXME:
    dirty = true
  end

  if dirty then
    self.messages = messages
    self.visible = #self.messages > 0
    Util.try(self._render, self)
    return true
  end
  return false
end

function View:height()
  local ret = 0
  for _, m in ipairs(self.messages) do
    ret = ret + m:height()
  end
  return ret
end

function View:width()
  local ret = 0
  for _, m in ipairs(self.messages) do
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
      self.messages
    ),
    "\n"
  )
end

---@param bufnr number buffer number
---@param linenr_start? number line number (1-indexed)
function View:highlight(bufnr, linenr_start)
  linenr_start = linenr_start or 1
  for _, m in ipairs(self.messages) do
    m:highlight(bufnr, Config.ns, linenr_start)
    m:highlight_cursor(bufnr, Config.ns, linenr_start)
    linenr_start = linenr_start + m:height()
  end
end

---@param bufnr number buffer number
---@param linenr_start? number line number (1-indexed)
function View:render(bufnr, linenr_start)
  linenr_start = linenr_start or 1
  vim.api.nvim_buf_set_lines(bufnr, linenr_start - 1, -1, false, {})
  for _, m in ipairs(self.messages) do
    m:render(bufnr, Config.ns, linenr_start)
    m:highlight_cursor(bufnr, Config.ns, linenr_start)
    linenr_start = linenr_start + m:height()
  end
end

---@alias NoiceView.constructor fun(render: string|NoiceRender, opts?: table): NoiceView
---@type NoiceView|NoiceView.constructor
local NoiceView = View
return NoiceView
