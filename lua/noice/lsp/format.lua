local require = require("noice.util.lazy")

local Markdown = require("noice.text.markdown")

---@alias MarkedString string | { language: string; value: string }
---@alias MarkupContent { kind: ('plaintext' | 'markdown'), value: string}
---@alias MarkupContents MarkedString | MarkedString[] | MarkupContent

local M = {}

-- Formats the content and adds it to the message
---@param contents MarkupContents Markup content
function M.format_markdown(contents)
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
    elseif vim.tbl_islist(content) then
      vim.list_extend(parts, M.format_markdown(content))
    else
      error("Unknown markup " .. vim.inspect(content))
    end
  end

  return vim.split(table.concat(parts, "\n"), "\n")
end

-- Formats the content and adds it to the message
---@param contents MarkupContents Markup content
---@param message NoiceMessage Noice message
---@param opts? MarkdownFormatOptions
function M.format(message, contents, opts)
  local text = table.concat(M.format_markdown(contents), "\n")
  Markdown.format(message, text, opts)
  return message
end

return M
