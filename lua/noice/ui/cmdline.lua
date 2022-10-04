local require = require("noice.util.lazy")

local Message = require("noice.message")
local Manager = require("noice.manager")
local Config = require("noice.config")
local NuiText = require("nui.text")

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

function M.update()
  M.message:clear()
  local count = 0
  for _, cmdline in ipairs(M.cmdlines) do
    if cmdline then
      count = count + 1
      if M.message:height() > 0 then
        M.message:newline()
      end

      local icon = Config.options.cmdline.icons[cmdline.firstc]
      local icon_width = 0
      local firstc = true
      if icon then
        firstc = icon.firstc ~= false
        icon_width = vim.api.nvim_strwidth(icon.icon) + 1
        M.message:append(NuiText("", {
          virt_text = { { icon.icon, icon.hl_group } },
          virt_text_win_col = 0,
        }))
        M.message:append((" "):rep(icon_width))
      end

      M.message:append(cmdline:chunks(firstc))
      M.message:append(" ")
      local pos = cmdline.pos + vim.api.nvim_strwidth(cmdline.prompt) + (firstc and #cmdline.firstc or 0) + icon_width
      M.message.cursor = { line = M.message:height(), col = pos, offset = pos - cmdline.pos }
    end
  end

  if count > 0 then
    Manager.add(M.message)
  else
    Manager.remove(M.message)
  end
end

return M
