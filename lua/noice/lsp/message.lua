local require = require("noice.util.lazy")

local Manager = require("noice.message.manager")
local Message = require("noice.message")
local Util = require("noice.util")

local M = {}

---@enum MessageType
M.message_type = {
  error = 1,
  warn = 2,
  info = 3,
  debug = 4,
}

---@alias ShowMessageParams {type:MessageType, message:string}

function M.setup()
  vim.lsp.handlers["window/showMessage"] = Util.protect(M.on_message)
end

---@param result ShowMessageParams
function M.on_message(_, result, ctx)
  ---@type number
  local client_id = ctx.client_id
  local client = vim.lsp.get_client_by_id(client_id)
  local client_name = client and client.name or string.format("lsp id=%d", client_id)

  local message = Message(M.event, "message", result.message)
  message.opts.title = "LSP Message (" .. client_name .. ")"
  for level, type in pairs(M.message_type) do
    if type == result.type then
      message.level = level
    end
  end
  Manager.add(message)
end

return M
