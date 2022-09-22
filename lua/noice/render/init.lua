local Message = require("noice.message")

local M = {}

---@alias RenderFunc fun(renderer: Renderer)

---@class Renderer
---@field _render RenderFunc
---@field message noice.Message
---@field opts? table
---@field dirty boolean
---@field _clear boolean
---@field visible boolean
local Renderer = {}
Renderer.__index = Renderer

---@param render string|RenderFunc
---@param opts? table
function M.new(render, opts)
  return setmetatable({
    _render = type(render) == "function" and render or M[render],
    message = Message(),
    opts = opts or {},
    dirty = false,
    visible = true,
  }, Renderer)
end

function Renderer:render()
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

function Renderer:show()
  self.dirty = self.visible == false
  self.visible = true
end

function Renderer:hide()
  self.dirty = self.visible == true
  self.visible = false
end

function Renderer:clear()
  self._clear = true
end

---@param chunks (noice.Chunk|NuiLine|NuiText)[]
function Renderer:add(chunks)
  if self._clear then
    self.message:clear()
    self._clear = false
  end
  self.dirty = true
  self.visible = true

  self.message:append(chunks)
end

setmetatable(M, {
  __index = function(_, key)
    return require("noice.render." .. key)
  end,
})

return M
