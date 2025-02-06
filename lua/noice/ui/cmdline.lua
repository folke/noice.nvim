local require = require("noice.util.lazy")

local Config = require("noice.config")
local Hacks = require("noice.util.hacks")
local Manager = require("noice.message.manager")
local Message = require("noice.message")
local NoiceText = require("noice.text")
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
M.real_cursor = vim.api.nvim__redraw ~= nil

--Neovim > 0.11 handles confirm messages in two steps
-- 1. msg_show.confirm with the message
-- 2. cmdline_show with Yes/No/Cancel
M.handle_confirm = vim.fn.has("nvim-0.11") == 1
M.confirm_message = nil ---@type NoiceMessage?
M._on_hide = nil ---@type fun()

---@alias NoiceCmdlineFormatter fun(cmdline: NoiceCmdline): {icon?:string, offset?:number, view?:NoiceViewOptions}

---@class CmdlineState
---@field content {[1]: integer, [2]: string}[]
---@field pos number
---@field firstc string
---@field prompt string
---@field indent number
---@field level number
---@field block? table

---@class CmdlineFormat
---@field name string
---@field kind string
---@field pattern? string|string[]
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

  ---@type {offset:number, format: CmdlineFormat}[]
  local ret = {}

  for _, format in pairs(Config.options.cmdline.format) do
    local patterns = type(format.pattern) == "table" and format.pattern or { format.pattern }
    ---@cast patterns string[]
    for _, pattern in ipairs(patterns) do
      local from, to = line:find(pattern)
      -- if match and cmdline pos is visible
      if from and self.state.pos >= to - 1 then
        ret[#ret + 1] = {
          offset = to or 0,
          format = format,
        }
      end
    end
  end
  table.sort(ret, function(a, b)
    return a.offset > b.offset
  end)
  local format = ret[1]
  if format then
    self.offset = format.format.conceal and format.offset or 0
    return format.format
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
  message.fix_cr = false
  message.title = nil

  local use_input = self.state.prompt ~= ""
    and format.view == "cmdline_input"
    and #self.state.prompt <= 60
    and not self.state.prompt:find("\n")

  if format.icon and (format.name ~= "input" or use_input) then
    message:append(NoiceText.virtual_text(format.icon, format.icon_hl_group))
    message:append(" ")
  end

  if not text_only then
    message.kind = format.name
  end

  if self.state.prompt ~= "" then
    if use_input then
      message.title = " " .. self.state.prompt:gsub("%s*:%s*$", "") .. " "
    else
      message:append(self.state.prompt, "NoiceCmdlinePrompt")
    end
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
    cursor.enabled = not M.real_cursor
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
M.skipped = false

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

  if M.confirm_message then
    local message = M.confirm_message --[[@as NoiceMessage]]
    message:append(prompt)
    M.confirm_message = nil
    Manager.add(message)
    M._on_hide = function()
      vim.schedule(function()
        Manager.remove(message)
      end)
    end
    return
  end

  -- This was triggered by a force redraw, so skip it
  if c:get():find(Hacks.SPECIAL, 1, true) then
    M.skipped = true
    return
  end
  M.skipped = false

  local last = M.cmdlines[level] and M.cmdlines[level].state
  if not vim.deep_equal(c.state, last) then
    M.active = c
    M.cmdlines[level] = c
    M.update()
  end
end

function M.on_hide(_, level)
  if M._on_hide then
    M._on_hide()
    M._on_hide = nil
  end
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
  if M.skipped then
    return
  end
  local c = M.cmdlines[level]
  if c and c.state.pos ~= pos then
    M.cmdlines[level].state.pos = pos
    M.update()
  end
end

---@class CmdlinePosition
---@field win number Window containing the cmdline
---@field buf number Buffer containing the cmdline
---@field cursor number
---@field bufpos {row:number, col:number} (1-0)-indexed position of the cmdline in the buffer
---@field screenpos {row:number, col:number} (1-0)-indexed screen position of the cmdline
M.position = nil

function M.fix_cursor()
  local win = M.win()
  if not win or not M.real_cursor then
    return
  end
  vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(M.position.buf), M.position.cursor })
  vim.api.nvim__redraw({ cursor = true, win = win, flush = true })
end

function M.win()
  return M.position and M.position.win and vim.api.nvim_win_is_valid(M.position.win) and M.position.win or nil
end

---@param buf number
---@param line number
---@param byte number
function M.on_render(_, buf, line, byte)
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    return
  end

  Hacks.cmdline_force_redraw()

  local cmdline_start = byte - (M.last():length() - M.last().offset)
  local cursor = byte - M.last():length() + M.last().state.pos
  local pos = vim.fn.screenpos(win, line, cmdline_start)

  M.position = {
    cursor = cursor,
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
  vim.g.ui_cmdline_pos = {
    M.position.screenpos.row,
    M.position.screenpos.col - 1,
  }
  pcall(M.fix_cursor)
end

function M.last()
  local last = math.max(1, unpack(vim.tbl_keys(M.cmdlines)))
  return M.cmdlines[last]
end

---@param message NoiceMessage
function M.on_confirm(message)
  if not M.handle_confirm then
    return false
  end
  M.confirm_message = message
  return true
end

function M.update()
  M.message:clear()
  local cmdline = M.last()

  if cmdline then
    cmdline:format(M.message)
    if not M.real_cursor then
      Hacks.hide_cursor()
    end
    Manager.add(M.message)
  else
    Manager.remove(M.message)
    if not M.real_cursor then
      Hacks.show_cursor()
    end
  end
end

return M
