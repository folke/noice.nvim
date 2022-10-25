local require = require("noice.util.lazy")

local Message = require("noice.message")
local Manager = require("noice.message.manager")
local NoiceText = require("noice.text")
local Config = require("noice.config")

local M = {}

---@alias LspEvent "lsp"
M.event = "lsp"

---@enum LspKind
M.kinds = {
  progress = "progress",
  hover = "hover",
}

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
    end
  end
  return message
end

function M.setup()
  if Config.options.lsp.hover.enabled then
    vim.lsp.handlers["textDocument/hover"] = M.hover
  end
  if Config.options.lsp.progress.enabled then
    require("noice.source.lsp.progress").setup()
  end
end

---@param message NoiceMessage
function M.close_on_move(message)
  local open = true
  message.opts.timeout = 100
  message.opts.keep = function()
    return open
  end
  vim.api.nvim_create_autocmd("CursorMoved", {
    callback = function()
      open = false
    end,
    once = true,
  })
end

function M.hover(_, result)
  if not (result and result.contents) then
    vim.notify("No information available")
    return
  end

  local message = M.format(result.contents, "hover")
  M.close_on_move(message)
  Manager.add(message)
end

return M
