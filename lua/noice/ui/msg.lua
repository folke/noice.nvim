local Handlers = require("noice.handlers")

local M = {}

---@enum noice.MsgKind
M.kinds = {
  empty = "", -- (empty) Unknown (consider a feature-request: |bugs|)
  confirm = "confirm", -- |confirm()| or |:confirm| dialog
  confirm_sub = "confirm_sub", -- |:substitute| confirm dialog |:s_c|
  emsg = "emsg", --  Error (|errors|, internal error, |:throw|, …)
  echo = "echo", --  |:echo| message
  echomsg = "echomsg", -- |:echomsg| message
  echoerr = "echoerr", -- |:echoerr| message
  lua_error = "lua_error", -- Error in |:lua| code
  rpc_error = "rpc_error", -- Error response from |rpcrequest()|
  return_prompt = "return_prompt", -- |press-enter| prompt after a multiple messages
  quickfix = "quickfix", -- Quickfix navigation message
  search_count = "search_count", -- Search count message ("S" flag of 'shortmess')
  wmsg = "wmsg", --  Warning ("search hit BOTTOM", |W10|, …)
}

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

---@param kind noice.MsgKind
function M.on_show(event, kind, content, replace_last)
  if kind == M.kinds.return_prompt then
    return vim.api.nvim_input("<cr>")
  end

  if kind == M.kinds.confirm then
    return M.on_confirm(event, kind, content)
  end

  local clear_kinds = { M.kinds.echo }
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
