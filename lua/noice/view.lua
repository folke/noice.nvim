local Message = require("noice.message")

---@alias noice.Renderer fun(view: noice.View)

---@class noice.View
---@field _render noice.Renderer
---@field message noice.Message
---@field opts? table
---@field dirty boolean
---@field _clear boolean
---@field visible boolean
local View = {}
View.__index = View

function View:render()
  if self.dirty then
    local ok, err = pcall(self._render, self)
    if not ok then
      vim.notify(err, "error", { title = "Messages" })
    end
    self.dirty = false
    return true
  end
  return false
end

function View:show()
  self.dirty = self.visible == false
  self.visible = true
end

function View:hide()
  self.dirty = self.visible == true
  self.visible = false
end

function View:clear()
  self._clear = true
end

---@param chunks (noice.Chunk|NuiLine|NuiText)[]
function View:add(chunks)
  if self._clear then
    self.message:clear()
    self._clear = false
  end
  self.dirty = true
  self.visible = true

  self.message:append(chunks)
end

---@param render string|noice.Renderer
---@param opts? table
return function(render, opts)
  return setmetatable({
    _render = type(render) == "function" and render or require("noice.render")[render],
    message = Message(),
    opts = opts or {},
    dirty = false,
    visible = true,
  }, View)
end
