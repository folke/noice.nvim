local Config = require("noice.config")
local Handlers = require("noice.handlers")

local M = {}

---@class Cmdline
---@field content table
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

---@type Cmdline[]
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
    if firstc == "/" or firstc == "?" then
      require("noice.hacks").fix_incsearch(true)
    end
    M.cmdlines[level] = c
    M.update()
  end
end

function M.on_hide(_, level)
  M.cmdlines[level] = nil
  require("noice.hacks").fix_incsearch(false)
  M.update()
end

function M.on_pos(_, pos, level)
  M.cmdlines[level].pos = pos
  M.update()
end

function M.update()
  local chunks = {}
  local line = 1
  for _, cmdline in ipairs(M.cmdlines) do
    if cmdline then
      if line > 1 then
        table.insert(chunks, { 0, "\n" })
      end
      vim.list_extend(chunks, cmdline:chunks())
      table.insert(chunks, {
        hl_group = "Cursor",
        line = line - 1,
        col = cmdline.pos + 1,
        end_col = cmdline.pos + 2,
      })
      line = line + 1
    end
  end

  if #chunks > 0 then
    local opts = Config.options.cmdline.syntax_highlighting and { filetype = "vim" } or {}
    Handlers.handle({
      event = "cmdline",
      chunks = chunks,
      opts = opts,
      clear = true,
      nowait = true,
    })
  else
    Handlers.handle({
      event = "cmdline",
      hide = true,
    })
  end
end

return M
