local require = require("noice.util.lazy")

local Manager = require("noice.manager")
local Message = require("noice.message")

local M = {}

---@enum MsgEvent
M.events = {
  show = "msg_show",
  clear = "msg_clear",
  showmode = "msg_showmode",
  showcmd = "msg_showcmd",
  ruler = "msg_ruler",
  history_show = "msg_history_show",
  history_clear = "msg_history_clear",
}

---@enum MsgKind
M.kinds = {
  -- echo
  empty = "", -- (empty) Unknown (consider a feature-request: |bugs|)
  echo = "echo", --  |:echo| message
  echomsg = "echomsg", -- |:echomsg| message
  -- input related
  confirm = "confirm", -- |confirm()| or |:confirm| dialog
  confirm_sub = "confirm_sub", -- |:substitute| confirm dialog |:s_c|
  return_prompt = "return_prompt", -- |press-enter| prompt after a multiple messages
  -- error/warnings
  emsg = "emsg", --  Error (|errors|, internal error, |:throw|, …)
  echoerr = "echoerr", -- |:echoerr| message
  lua_error = "lua_error", -- Error in |:lua| code
  rpc_error = "rpc_error", -- Error response from |rpcrequest()|
  wmsg = "wmsg", --  Warning ("search hit BOTTOM", |W10|, …)
  -- hints
  quickfix = "quickfix", -- Quickfix navigation message
  search_count = "search_count", -- Search count message ("S" flag of 'shortmess')
}

---@type NoiceMessage
M.last = nil
M.clear = false
---@type NoiceMessage[]
M._messages = {}

function M.get(event, kind)
  local id = event .. "." .. (kind or "")
  if not M._messages[id] then
    M._messages[id] = Message(event, kind)
  end
  return M._messages[id]
end

---@param kind MsgKind
---@param content NoiceContent[]
function M.on_show(event, kind, content, replace_last)
  if M.clear then
    Manager.clear({ event = "msg_show" })
    M.clear = false
  end

  if kind == M.kinds.return_prompt then
    return M.on_return_prompt()
  elseif kind == M.kinds.confirm or kind == M.kinds.confirm_sub then
    return M.on_confirm(event, kind, content)
  end

  if M.last and replace_last then
    Manager.clear({ message = M.last })
    M.last = nil
  end

  local message = Message(event, kind, content)
  message:trim_empty_lines()

  M.last = message

  Manager.add(message)
end

function M.on_clear()
  M.last = nil
  M.clear = true
end

-- mode like recording...
function M.on_showmode(event, content)
  local message = M.get(event)
  if vim.tbl_isempty(content) then
    if event == "msg_showmode" then
      Manager.remove(message)
    end
  else
    message:set(content)
    Manager.add(message)
  end
end
M.on_showcmd = M.on_showmode
M.on_ruler = M.on_showmode

function M.on_return_prompt()
  return vim.api.nvim_input("<cr>")
end

---@param content NoiceChunk[]
function M.on_confirm(event, kind, content)
  local message = Message(event, kind, content)
  message:append(" ")
  message.cursor = { line = message:height(), col = message:last_line():width() - 1 }
  Manager.add(message)
  vim.schedule(function()
    Manager.remove(message)
  end)
end

---@param entries { [1]: string, [2]: NoiceChunk[]}[]
function M.on_history_show(event, entries)
  local contents = {}
  for _, e in pairs(entries) do
    local content = e[2]
    table.insert(contents, { 0, "\n" })
    vim.list_extend(contents, content)
  end
  local message = M.get(event)
  message:set(contents)
  Manager.add(message)
end

function M.on_history_clear() end

return M
