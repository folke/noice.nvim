local Block = require("noice.block")
local Filter = require("noice.filter")
local Config = require("noice.config")

local _id = 0

---@class NoiceMessage: NoiceBlock
---@field super NoiceBlock
---@field id number
---@field event NoiceEvent
---@field ctime number
---@field mtime number
---@field tick number
---@field kind? NoiceKind
---@field cursor? { line: integer, col: integer, buf?: number, buf_line?: number }
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
  Message.super.init(self)

  self:_debug()

  if content then
    self:append(content)
  end
end

function Message:_debug()
  if Config.options.debug then
    self:append("[" .. self.id .. "] " .. self.event .. "." .. (self.kind or ""), "DiagnosticVirtualTextInfo")
    self:append(" ")
  end
end

function Message:content(hide_debug)
  local ret = Message.super.content(self)
  if hide_debug and Config.options.debug and self:height() > 0 then
    local debug_width = self._lines[1]._texts[1]:width() + 1
    ---@type string
    ret = ret:sub(debug_width + 1):gsub("^\n", "")
  end
  return ret
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr_start number line number (1-indexed)
function Message:highlight_cursor(bufnr, ns_id, linenr_start)
  if self.cursor then
    self.cursor.buf = bufnr
    self.cursor.buf_line = self.cursor.line + linenr_start - 1
    local line_width = self._lines[self.cursor.line]:width()
    if self.cursor.col >= line_width then
      -- end of line, so use a virtual text
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, self.cursor.buf_line - 1, 0, {
        virt_text = { { " ", "Cursor" } },
        virt_text_win_col = self.cursor.col,
      })
    else
      -- use a regular extmark
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, self.cursor.buf_line - 1, self.cursor.col, {
        end_col = self.cursor.col + 1,
        hl_group = "Cursor",
      })
    end
  end
end

function Message:clear()
  Message.super.clear(self)
  self:_debug()
  self.cursor = nil
end

Message.is = Filter.is

---@alias NoiceMessage.constructor fun(event: NoiceEvent, kind?: NoiceKind, content?: NoiceContent|NoiceContent[]): NoiceMessage
---@type NoiceMessage|NoiceMessage.constructor
local NoiceMessage = Message

return NoiceMessage
