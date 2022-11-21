local require = require("noice.util.lazy")

local Message = require("noice.message")
local Manager = require("noice.message.manager")
local Config = require("noice.config")
local NoiceText = require("noice.text")
local Hacks = require("noice.util.hacks")
local Object = require("nui.object")

local M = {}
M.message = Message("cmdline", nil)

---@enum CmdlineEvent
M.events = {
  cmdline = "cmdline",
  show = "cmdline_show",
  hide = "cmdline_hide",
  pos = "cmdline_pos",
  special_char = "cmdline_special_char",
  block_show = "cmdline_block_show",
  block_append = "cmdline_block_append",
  block_hide = "cmdline_block_hide",
}

---@type NoiceCmdline?
M.active = nil

---@alias NoiceCmdlineFormatter fun(cmdline: NoiceCmdline): {icon?:string, offset?:number, view?:NoiceViewOptions}

---@class CmdlineState
---@field content {[1]: integer, [2]: string}[]
---@field pos number
---@field firstc string
---@field prompt string
---@field indent number
---@field level number
---@field block table

---@class CmdlineFormat
---@field kind string
---@field pattern? string
---@field view string
---@field conceal? boolean
---@field icon? string
---@field icon_hl_group? string
---@field opts? NoiceViewOptions
---@field title? string
---@field lang? string

---@class NoiceCmdline
---@field state CmdlineState
---@field offset integer
---@overload fun(state:CmdlineState): NoiceCmdline
local Cmdline = Object("NoiceCmdline")

---@param state CmdlineState
function Cmdline:init(state)
  self.state = state or {}
  self.offset = 0
end

function Cmdline:get()
  return table.concat(
    vim.tbl_map(function(c)
      return c[2]
    end, self.state.content),
    ""
  )
end

---@return CmdlineFormat
function Cmdline:get_format()
  if self.state.prompt and self.state.prompt ~= "" then
    return Config.options.cmdline.format.input
  end
  local line = self.state.firstc .. self:get()

  ---@type table<string, CmdlineFormat>
  local formats = vim.tbl_values(vim.tbl_filter(function(f)
    return f.pattern
  end, Config.options.cmdline.format))
  table.sort(formats, function(a, b)
    return #a.pattern > #b.pattern
  end)

  for _, format in pairs(formats) do
    local from, to = line:find(format.pattern)
    -- if match and cmdline pos is visible
    if from and self.state.pos >= to - 1 then
      self.offset = format.conceal and to or 0
      return format
    end
  end
  self.offset = 0
  return {
    kind = self.state.firstc,
    view = "cmdline_popup",
  }
end

---@param message NoiceMessage
---@param text_only? boolean
function Cmdline:format(message, text_only)
  local format = self:get_format()

  if format.icon then
    message:append(NoiceText.virtual_text(format.icon, format.icon_hl_group))
    message:append(" ")
  end

  if not text_only then
    message.kind = format.kind
  end

  -- FIXME: prompt
  if self.state.prompt ~= "" then
    message:append(self.state.prompt, "NoiceCmdlinePrompt")
  end

  if not format.conceal then
    message:append(self.state.firstc)
  end

  local cmd = self:get():sub(self.offset)

  message:append(cmd)

  if format.lang then
    message:append(NoiceText.syntax(format.lang, 1, -vim.fn.strlen(cmd)))
  end

  if not text_only then
    local cursor = NoiceText.cursor(-self:length() + self.state.pos)
    cursor.on_render = M.on_render
    message:append(cursor)
  end
end

function Cmdline:width()
  return vim.api.nvim_strwidth(self:get())
end

function Cmdline:length()
  return vim.fn.strlen(self:get())
end

---@type NoiceCmdline[]
M.cmdlines = {}

function M.on_show(event, content, pos, firstc, prompt, indent, level)
  local c = Cmdline({
    event = event,
    content = content,
    pos = pos,
    firstc = firstc,
    prompt = prompt,
    indent = indent,
    level = level,
  })
  local last = M.cmdlines[level] and M.cmdlines[level].state
  if not vim.deep_equal(c.state, last) then
    M.active = c
    M.cmdlines[level] = c
    M.update()
  end
end

function M.on_hide(_, level)
  if M.cmdlines[level] then
    M.cmdlines[level] = nil
    local active = M.active
    vim.defer_fn(function()
      if M.active == active then
        M.active = nil
      end
    end, 100)
    M.update()
  end
end

function M.on_pos(_, pos, level)
  if M.cmdlines[level] and M.cmdlines[level].state.pos ~= pos then
    M.cmdlines[level].state.pos = pos
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
  Hacks.cmdline_force_redraw()
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    -- FIXME: check with cmp
    -- FIXME: state.pos?
    local cmdline_start = byte - (M.last():length() - M.last().offset)

    local cursor = byte - M.last():length() + M.last().state.pos
    vim.api.nvim_win_set_cursor(win, { 1, cursor })
    vim.api.nvim_win_call(win, function()
      vim.cmd([[noautocmd silent! normal! ze]])
    end)

    local pos = vim.fn.screenpos(win, line, cmdline_start)
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
  local cmdline = M.last()

  if cmdline then
    cmdline:format(M.message)
    Hacks.hide_cursor()
    Manager.add(M.message)
  else
    Manager.remove(M.message)
    Hacks.show_cursor()
  end
end

return M
