local require = require("noice.util.lazy")

local Message = require("noice.message")
local Manager = require("noice.message.manager")
local Config = require("noice.config")
local NoiceText = require("noice.text")
local Util = require("noice.util")

local M = {}
M.message = Message("cmdline", nil)

---@enum CmdlineEvent
M.events = {
  show = "cmdline_show",
  hide = "cmdline_hide",
  pos = "cmdline_pos",
  special_char = "cmdline_special_char",
  block_show = "cmdline_block_show",
  block_append = "cmdline_block_append",
  block_hide = "cmdline_block_hide",
}

--- TODO: add injection for ! as shell in nvim-treesitter

---@class NoiceCmdline
---@field content {[1]: integer, [2]: string}[]
---@field pos number
---@field firstc string
---@field prompt string
---@field indent number
---@field level number
---@field block table
local Cmdline = {}
Cmdline.__index = Cmdline

function Cmdline:chunks(firstc)
  local chunks = {}

  -- indent content
  if #self.content > 0 then
    self.content[1][2] = string.rep(" ", self.indent) .. self.content[1][2]
  end

  -- prefix with first character and optional prompt
  table.insert(chunks, { 0, (firstc and self.firstc or "") .. self.prompt })

  -- add content
  vim.list_extend(chunks, self.content)

  return chunks
end

function Cmdline:get()
  return table.concat(
    vim.tbl_map(function(c)
      return c[2]
    end, self.content),
    ""
  )
end

function Cmdline:width()
  return vim.api.nvim_strwidth(self:get())
end

function Cmdline:length()
  return vim.fn.strlen(self:get())
end

---@type NoiceCmdline[]
M.cmdlines = {}

---@param opts table
function M.new(opts)
  return setmetatable(opts, Cmdline)
end

function M.on_show(event, content, pos, firstc, prompt, indent, level)
  local c = M.new({
    event = event,
    content = content,
    pos = pos,
    firstc = firstc,
    prompt = prompt,
    indent = indent,
    level = level,
  })
  if not vim.deep_equal(c, M.cmdlines[level]) then
    M.cmdlines[level] = c
    M.update()
  end
end

function M.on_hide(_, level)
  M.cmdlines[level] = nil
  M.update()
end

function M.on_pos(_, pos, level)
  if M.cmdlines[level] then
    M.cmdlines[level].pos = pos
    M.update()
  end
end

---@class CmdlinePosition
---@field win number Window containing the cmdline
---@field buf number Buffer containing the cmdline
---@field bufpos {row:number, col:number} (1-0)-indexed position of the cmdline in the buffer
---@field screenpos {row:number, col:number} (1-0)-indexed screen position of the cmdline
M.position = nil

---@param buf number
---@param line number
---@param byte number
function M.on_render(_, buf, line, byte)
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    local cmdline_start = byte - M.last():length()
    local pos = vim.fn.screenpos(win, line, cmdline_start + 1)
    M.position = {
      buf = buf,
      win = win,
      bufpos = {
        row = line,
        col = cmdline_start,
      },
      screenpos = {
        row = pos.row,
        col = pos.col - 1,
      },
    }
  end
end

function M.last()
  local last = math.max(1, unpack(vim.tbl_keys(M.cmdlines)))
  return M.cmdlines[last]
end

function M.update()
  M.message:clear()
  local count = 0
  Util.for_each(M.cmdlines, function(_, cmdline)
    count = count + 1
    if M.message:height() > 0 then
      M.message:newline()
    end

    local icon = Config.options.cmdline.icons[cmdline.firstc]

    if icon then
      M.message:append(NoiceText.virtual_text(icon.icon, icon.hl_group))
      M.message:append(" ")
    end

    M.message:append(cmdline:chunks(icon and icon.firstc ~= false))
    local cursor = NoiceText.cursor(-cmdline:length() + cmdline.pos)
    cursor.on_render = M.on_render
    M.message:append(cursor)
  end)

  if count > 0 then
    Manager.add(M.message)
  else
    Manager.remove(M.message)
  end
end

return M
