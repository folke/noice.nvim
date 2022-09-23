local Block = require("noice.block")
local Filter = require("noice.filter")
local Config = require("noice.config")

---@class NoiceMessage: NoiceBlock
---@field event NoiceEvent
---@field kind? NoiceKind
---@field keep boolean
---@diagnostic disable-next-line: undefined-field
local Message = Block:extend("NoiceBlock")

---@param event NoiceEvent
---@param kind? NoiceKind
---@param content? NoiceContent|NoiceContent[]
function Message:init(event, kind, content)
  self.event = event
  self.kind = kind
  self.keep = true
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
