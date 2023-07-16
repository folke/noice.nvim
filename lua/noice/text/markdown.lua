local require = require("noice.util.lazy")

local NoiceText = require("noice.text")
local Config = require("noice.config")

---@alias MarkdownBlock {line:string}
---@alias MarkdownCodeBlock {code:string[], lang:string}
---@alias Markdown (MarkdownBlock|MarkdownCodeBlock)[]

local M = {}

function M.is_rule(line)
  return line and line:find("^%s*[%*%-_][%*%-_][%*%-_]+%s*$")
end

function M.is_code_block(line)
  return line and line:find("^%s*```")
end

function M.is_empty(line)
  return line and line:find("^%s*$")
end

-- TODO:: upstream to treesitter
-- ((backslash_escape) @conceal (#set! conceal "_") (#contains? @conceal "\_"))

---@param text string
function M.html_entities(text)
  local entities = { nbsp = "", lt = "<", gt = ">", amp = "&", quot = '"', apos = "'", ensp = " ", emsp = " " }
  for entity, char in pairs(entities) do
    text = text:gsub("&" .. entity .. ";", char)
  end
  return text
end

--- test\_foo
---@param buf buffer
---@param range number[]
function M.conceal_escape_characters(buf, ns, range)
  local chars = "\\`*_{}[]()#+-.!/"
  local regex = "\\["
  for i = 1, #chars do
    regex = regex .. "%" .. chars:sub(i, i)
  end
  regex = regex .. "]"

  local lines = vim.api.nvim_buf_get_lines(buf, range[1], range[3] + 1, false)

  for l, line in ipairs(lines) do
    local c = line:find(regex)
    while c do
      vim.api.nvim_buf_set_extmark(buf, ns, range[1] + l - 1, c - 1, {
        end_col = c,
        conceal = "",
      })
      c = line:find(regex, c + 1)
    end
  end
end

-- This is a <code>test</code> **booo**
---@param text string
---@param opts? MarkdownFormatOptions
function M.parse(text, opts)
  opts = opts or {}
  ---@type string
  text = text:gsub("</?pre>", "```"):gsub("\r", "")
  -- text = text:gsub("</?code>", "`")
  text = M.html_entities(text)

  ---@type Markdown
  local ret = {}

  local lines = vim.split(text, "\n")

  local l = 1

  local function eat_nl()
    while M.is_empty(lines[l + 1]) do
      l = l + 1
    end
  end

  while l <= #lines do
    local line = lines[l]
    if M.is_empty(line) then
      local is_start = l == 1
      eat_nl()
      local is_end = l == #lines
      if not (M.is_code_block(lines[l + 1]) or M.is_rule(lines[l + 1]) or is_start or is_end) then
        table.insert(ret, { line = "" })
      end
    elseif M.is_code_block(line) then
      ---@type string
      local lang = line:match("```%s*(%S+)") or opts.ft or "text"
      local block = { lang = lang, code = {} }
      while lines[l + 1] and not M.is_code_block(lines[l + 1]) do
        table.insert(block.code, lines[l + 1])
        l = l + 1
      end

      local prev = ret[#ret]
      if prev and not M.is_rule(prev.line) then
        table.insert(ret, { line = "" })
      end

      table.insert(ret, block)
      l = l + 1
      eat_nl()
    elseif M.is_rule(line) then
      table.insert(ret, { line = "---" })
      eat_nl()
    else
      local prev = ret[#ret]
      if prev and prev.code then
        table.insert(ret, { line = "" })
      end
      table.insert(ret, { line = line })
    end
    l = l + 1
  end

  return ret
end

function M.get_highlights(line)
  ---@type NoiceText[]
  local ret = {}
  for pattern, hl_group in pairs(Config.options.markdown.highlights) do
    local from = 1
    while from do
      ---@type number, string?
      local to, match
      ---@type number, number, string?
      from, to, match = line:find(pattern, from)
      if match then
        ---@type number, number
        from, to = line:find(match, from)
      end
      if from then
        table.insert(
          ret,
          NoiceText("", {
            hl_group = hl_group,
            col = from - 1,
            length = to - from + 1,
            -- priority = 120,
          })
        )
      end
      from = to and to + 1 or nil
    end
  end
  return ret
end

---@alias MarkdownFormatOptions {ft?: string}

---@param message NoiceMessage
---@param text string
---@param opts? MarkdownFormatOptions
--```lua
--local a = 1
--local b = true
--```
--foo tex
function M.format(message, text, opts)
  opts = opts or {}

  local blocks = M.parse(text, opts)

  local md_lines = 0

  local function emit_md()
    if md_lines > 0 then
      message:append(NoiceText.syntax("markdown", md_lines))
      md_lines = 0
    end
  end

  for l = 1, #blocks do
    local block = blocks[l]
    if block.code then
      emit_md()
      message:newline()
      ---@cast block MarkdownCodeBlock
      for c, line in ipairs(block.code) do
        message:append(line)
        if c == #block.code then
          message:append(NoiceText.syntax(block.lang, #block.code))
        else
          message:newline()
        end
      end
    else
      ---@cast block MarkdownBlock
      message:newline()
      if M.is_rule(block.line) then
        M.horizontal_line(message)
      else
        message:append(block.line)
        for _, t in ipairs(M.get_highlights(block.line)) do
          message:append(t)
        end
        md_lines = md_lines + 1
      end
    end
  end
  emit_md()
end

function M.keys(buf)
  if vim.b[buf].markdown_keys then
    return
  end

  local function map(lhs)
    vim.keymap.set("n", lhs, function()
      local line = vim.api.nvim_get_current_line()
      local pos = vim.api.nvim_win_get_cursor(0)
      local col = pos[2] + 1

      for pattern, handler in pairs(Config.options.markdown.hover) do
        local from = 1
        local to, url
        while from do
          from, to, url = line:find(pattern, from)
          if from and col >= from and col <= to then
            return handler(url)
          end
          if from then
            from = to + 1
          end
        end
      end
      vim.api.nvim_feedkeys(lhs, "n", false)
    end, { buffer = buf, silent = true })
  end

  map("gx")
  map("K")

  vim.b[buf].markdown_keys = true
end

---@param message NoiceMessage
function M.horizontal_line(message)
  message:append(NoiceText("", {
    virt_text_win_col = 0,
    virt_text = { { string.rep("─", vim.go.columns), "@punctuation.special.markdown" } },
    priority = 100,
  }))
end

return M
