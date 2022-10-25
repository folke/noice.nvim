local require = require("noice.util.lazy")

local Message = require("noice.message")
local NoiceText = require("noice.text")
local Config = require("noice.config")

local M = {}

---@alias MarkedString string | { language: string; value: string }
---@alias MarkupContent { kind: ('plaintext' | 'markdown'), value: string}
---@alias MarkupContents MarkedString | MarkedString[] | MarkupContent

---@param contents MarkupContents
---@param kind LspKind
function M.format(contents, kind)
  if type(contents) ~= "table" or not vim.tbl_islist(contents) then
    contents = { contents }
  end

  local parts = {}

  for _, content in ipairs(contents) do
    if type(content) == "string" then
      table.insert(parts, content)
    elseif content.language then
      table.insert(parts, ("```%s\n%s\n```"):format(content.language, content.value))
    elseif content.kind == "markdown" then
      table.insert(parts, content.value)
    elseif content.kind == "plaintext" then
      table.insert(parts, ("```\n%s\n```"):format(content.value))
    end
  end

  local text = table.concat(parts, "\n")
  text = text:gsub("\n\n\n", "\n\n")
  text = text:gsub("\n%s*\n```", "\n```")
  text = text:gsub("```\n%s*\n", "```\n")

  local lines = vim.split(text, "\n")

  local width = 50
  for _, line in pairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end

  local message = Message(M.event, kind)
  message.once = true
  message.opts.title = kind

  for _, line in ipairs(lines) do
    message:newline()
    -- Make the horizontal ruler extend the whole window width
    if line:find("^[%*%-_][%*%-_][%*%-_]+$") then
      message:append(NoiceText("", {
        virt_text_win_col = 0,
        virt_text = { { ("─"):rep(width), "@punctuation.special.markdown" } },
        priority = 100,
      }))
    else
      message:append(line)
      for pattern, hl_group in pairs(Config.options.lsp.hl_patterns) do
        local from, to, match = line:find(pattern)
        if match then
          from, to = line:find(match, from)
        end
        if from then
          message:append(NoiceText(" ", {
            hl_group = hl_group,
            col = from - 1,
            length = to - from + 1,
          }))
        end
      end
    end
  end
  return message
end

return M
