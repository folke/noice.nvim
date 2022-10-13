local require = require("noice.util.lazy")

local Block = require("noice.text.block")
local Filter = require("noice.message.filter")

local _id = 0

---@class NoiceMessage: NoiceBlock
---@field super NoiceBlock
---@field id number
---@field event NoiceEvent
---@field ctime number
---@field mtime number
---@field once? boolean
---@field tick number
---@field level? NotifyLevel
---@field kind? NoiceKind
---@field _debug? boolean
---@field opts table<string, any>
---@overload fun(event: NoiceEvent, kind?: NoiceKind, content?: NoiceContent|NoiceContent[]): NoiceMessage
---@diagnostic disable-next-line: undefined-field
local Message = Block:extend("NoiceBlock")

---@param event NoiceEvent
---@param kind? NoiceKind
---@param content? NoiceContent|NoiceContent[]
function Message:init(event, kind, content)
  _id = _id + 1
  self.id = _id
  self.tick = 1
  self.ctime = vim.fn.localtime()
  self.mtime = vim.fn.localtime()
  self.event = event
  self.kind = kind
  self.opts = {}
  Message.super.init(self, content)
end

Message.is = Filter.is

return Message
