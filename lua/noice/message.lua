local Block = require("noice.block")
local Filter = require("noice.filter")

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
  Message.super.init(self, content)
end

Message.is = Filter.is

---@alias NoiceMessage.constructor fun(event: NoiceEvent, kind?: NoiceKind, content?: NoiceContent|NoiceContent[]): NoiceMessage
---@type NoiceMessage|NoiceMessage.constructor
local NoiceMessage = Message

return NoiceMessage
