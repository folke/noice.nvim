local Config = require("noice.config")
local Util = require("noice.util")
local Filter = require("noice.filter")
local Object = require("nui.object")

---@alias NoiceRender fun(view: NoiceView)

---@class NoiceView
---@field _render NoiceRender
---@field messages NoiceMessage[]
---@field opts? table
---@field dirty boolean
---@field visible boolean
local View = Object("View")

---@param render string|NoiceRender
---@param opts? table
function View:init(render, opts)
  self._render = type(render) == "function" and render or require("noice.render")[render]
  self.messages = {}
  self.opts = opts or {}
  self.dirty = false
  self.visible = true
end

function View:update()
  if self.dirty then
    if #self.messages == 0 then
      self.visible = false
    end
    Util.try(self._render, self)
    self.dirty = false
    return true
  end
  return false
end

---@param filter NoiceFilter
---@param invert? boolean
function View:has(filter, invert)
  return Filter.has(self.messages, filter, invert)
end

---@param filter NoiceFilter
---@param invert? boolean
function View:get(filter, invert)
  return Filter.filter(self.messages, filter, invert)
end

-- Marks any messages for expiration (keep = false)
---@return NoiceMessage?
---@param filter NoiceFilter
function View:remove(filter)
  for _, message in ipairs(self:get(filter)) do
    message.keep = false
  end
  if self.opts.clear_on_remove then
    self:clear(filter)
  end
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
    linenr_start = linenr_start + m:height()
  end
end

---@param bufnr number buffer number
---@param linenr_start? number line number (1-indexed)
function View:render(bufnr, linenr_start)
  vim.api.nvim_buf_set_lines(bufnr, (linenr_start or 1) - 1, -1, false, {})
  linenr_start = linenr_start or 1
  for _, m in ipairs(self.messages) do
    m:render(bufnr, Config.ns, linenr_start)
    linenr_start = linenr_start + m:height()
  end
end

function View:show()
  self.dirty = self.visible == false
  self.visible = true
end

function View:hide()
  self.dirty = self.visible == true
  self.visible = false
end

-- Clears any expired messages (where keep = false)
---@param filter? NoiceFilter
function View:clear(filter)
  local clear = vim.tbl_deep_extend("keep", { keep = false }, filter or {})
  local count = #self.messages
  self.messages = self:get(clear, true)
  if count ~= #self.messages then
    self.dirty = true
  end
end

---@param message NoiceMessage
function View:add(message)
  self:clear()
  self.dirty = true
  self.visible = true
  message.keep = true
  table.insert(self.messages, message)
end

---@alias NoiceView.constructor fun(render: string|NoiceRender, opts?: table): NoiceView
---@type NoiceView|NoiceView.constructor
local NoiceView = View
return NoiceView
