local Message = require("noice.message")
local Scheduler = require("noice.scheduler")

local M = {}

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

function Cmdline:chunks()
  local chunks = {}

  -- indent content
  if #self.content > 0 then
    self.content[1][2] = string.rep(" ", self.indent) .. self.content[1][2]
  end

  -- prefix with first character and optional prompt
  table.insert(chunks, { 0, self.firstc .. self.prompt })

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
  local message = Message("cmdline", nil)

  local count = 0
  for _, cmdline in ipairs(M.cmdlines) do
    if cmdline then
      count = count + 1
      if message:height() > 0 then
        message:newline()
      end
      message:append(cmdline:chunks())
      local pos = cmdline.pos + #cmdline.prompt + #cmdline.firstc
      message:append({
        hl_group = "Cursor",
        line = message:height(),
        col = pos,
        end_col = pos + 1,
      })
    end
  end

  if count > 0 then
    -- local opts = Config.options.cmdline.syntax_highlighting and { filetype = "vim" } or {}
    Scheduler.schedule({
      message = message,
      remove = { event = "cmdline" },
      instant = true,
    })
  else
    Scheduler.schedule({
      remove = { event = "cmdline" },
      clear = { event = "cmdline" },
    })
  end
end

return M
