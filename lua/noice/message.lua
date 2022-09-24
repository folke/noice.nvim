local Block = require("noice.block")
local Filter = require("noice.filter")
local Config = require("noice.config")

local id = 0

---@class NoiceMessage: NoiceBlock
---@field id number
---@field event NoiceEvent
---@field ctime number
---@field mtime number
---@field kind? NoiceKind
---@field expired boolean
---@diagnostic disable-next-line: undefined-field
local Message = Block:extend("NoiceBlock")

---@param event NoiceEvent
---@param kind? NoiceKind
---@param content? NoiceContent|NoiceContent[]
function Message:init(event, kind, content)
  id = id + 1
  self.id = id
  self.ctime = vim.fn.localtime()
  self.mtime = vim.fn.localtime()
  self.event = event
  self.kind = kind
  self.expired = false
  ---@diagnostic disable-next-line: undefined-field
  Message.super.init(self)

  if Config.options.debug then
    local NuiText = require("nui.text")
    self:append(NuiText(event .. "." .. (kind or ""), "DiagnosticVirtualTextInfo"))
    self:append(NuiText(" ", "Normal"))
  end

  if content then
    self:append(content)
  end
end

Message.is = Filter.is

---@alias NoiceMessage.constructor fun(event: NoiceEvent, kind?: NoiceKind, content?: NoiceContent|NoiceContent[]): NoiceMessage
---@type NoiceMessage|NoiceMessage.constructor
local NoiceMessage = Message

return NoiceMessage
