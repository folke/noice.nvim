local Handlers = require("noice.handlers")

local M = {}

function M.on_clear()
  Handlers.handle({ event = "msg_clear" })
end

function M.on_showmode(event, content)
  if vim.tbl_isempty(content) then
    Handlers.handle({ event = event, clear = true })
  else
    Handlers.handle({ event = event, chunks = content, clear = true })
  end
end
M.on_showcmd = M.on_showmode
M.on_ruler = M.on_showmode

function M.on_show(event, kind, content, replace_last)
  if kind == "return_prompt" then
    return vim.api.nvim_input("<cr>")
  end

  if kind == "confirm" then
    return M.on_confirm(event, kind, content)
  end

  local clear_kinds = { "echo" }
  local clear = replace_last or vim.tbl_contains(clear_kinds, kind)

  Handlers.handle({
    event = event,
    kind = kind,
    chunks = content,
    clear = clear,
  })
end

function M.on_confirm(event, kind, content)
  local NuiText = require("nui.text")
  table.insert(content, NuiText(" ", "Cursor"))

  Handlers.handle({
    event = event,
    kind = kind,
    chunks = content,
    clear = true,
    nowait = true,
  })
  Handlers.handle({ event = event, kind = kind, hide = true })
end

function M.on_history_show(event, entries)
  local contents = {}
  for _, e in pairs(entries) do
    local _, content = unpack(e)
    table.insert(contents, { 0, "\n" })
    vim.list_extend(contents, content)
  end
  Handlers.handle({ event = event, chunks = contents })
end

function M.on_history_clear() end

return M
