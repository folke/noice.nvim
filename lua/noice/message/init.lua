local require = require("noice.util.lazy")

local Block = require("noice.text.block")
local Filter = require("noice.message.filter")
local Config = require("noice.config")

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
---@field opts table<string, any>
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

function Message:content(hide_debug)
  local ret = Message.super.content(self)
  if hide_debug and Config.options.debug and self:height() > 0 then
    local debug_width = self._lines[1]._texts[1]:length() + 1
    ---@type string
    ret = ret:sub(debug_width + 1):gsub("^\n", "")
  end
  return ret
end

Message.is = Filter.is

---@alias NoiceMessage.constructor fun(event: NoiceEvent, kind?: NoiceKind, content?: NoiceContent|NoiceContent[]): NoiceMessage
---@type NoiceMessage|NoiceMessage.constructor
local NoiceMessage = Message

return NoiceMessage
