local require = require("noice.util.lazy")

local Manager = require("noice.message.manager")
local Config = require("noice.config")
local Format = require("noice.lsp.format")
local Util = require("noice.util")
local Message = require("noice.message")
local Signature = require("noice.lsp.signature")

local M = {}

---@alias LspEvent "lsp"
M.event = "lsp"

---@enum LspKind
M.kinds = {
  progress = "progress",
  hover = "hover",
  message = "message",
  signature = "signature",
}

---@type table<string, NoiceMessage>
M._messages = {}

function M.get(kind)
  if not M._messages[kind] then
    M._messages[kind] = Message("lsp", kind)
    M._messages[kind].opts.title = kind
  end
  M._messages[kind]:clear()
  return M._messages[kind]
end

function M.setup()
  local group = vim.api.nvim_create_augroup("noice_lsp", {
    clear = true,
  })

  M.hover = Util.protect(M.hover)
  if Config.options.lsp.hover.enabled then
    vim.lsp.handlers["textDocument/hover"] = M.hover
  end

  M.signature = Util.protect(M.signature)
  if Config.options.lsp.signature.enabled then
    vim.lsp.handlers["textDocument/signatureHelp"] = M.signature
  end

  M.message = Util.protect(M.message)
  if Config.options.lsp.message.enabled then
    vim.lsp.handlers["window/showMessage"] = M.message
  end

  if Config.options.lsp.signature.auto_open.enabled then
    require("noice.lsp.signature").setup(group)
  end

  if Config.options.lsp.progress.enabled then
    require("noice.lsp.progress").setup()
  end

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertCharPre" }, {
    group = group,
    callback = function()
      vim.defer_fn(M.on_close, 10)
    end,
  })
end

---@enum MessageType
M.message_type = {
  error = 1,
  warn = 2,
  info = 3,
  debug = 4,
}

---@alias ShowMessageParams {type:MessageType, message:string}

---@param result ShowMessageParams
function M.message(_, result, ctx)
  local client_id = ctx.client_id
  local client = vim.lsp.get_client_by_id(client_id)
  local client_name = client and client.name or string.format("lsp id=%d", client_id)

  local message = Message(M.event, M.kinds.message, result.message)
  message.opts.title = "LSP Message (" .. client_name .. ")"
  for level, type in pairs(M.message_type) do
    if type == result.type then
      message.level = level
    end
  end
  message.once = true
  Manager.add(message)
end

function M.on_close()
  for _, message in pairs(M._messages) do
    -- close the message if we're not in it's buffer (focus)
    local keep = message:on_buf(vim.api.nvim_get_current_buf()) or (message.opts.stay and message.opts.stay())
    if not keep then
      M.hide(message)
    end
  end
end

function M.scroll(delta)
  for _, kind in ipairs({ M.kinds.hover, M.kinds.signature }) do
    local message = M.get(kind)
    local win = message:win()
    if win then
      Util.nui.scroll(win, delta)
      return true
    end
  end
end

---@param message NoiceMessage
function M.hide(message)
  message.opts.keep = function()
    return false
  end
  Manager.remove(message)
end

---@param message NoiceMessage
---@param stay? fun():boolean
function M.show(message, stay)
  message.opts.timeout = 100
  message.opts.keep = function()
    return true
  end
  message.opts.stay = stay
  for _, m in pairs(M._messages) do
    if m ~= message then
      M.hide(m)
    end
  end
  Manager.add(message)
end

---@param result SignatureHelp
function M.signature(_, result, ctx, config)
  config = config or {}
  if not (result and result.signatures) then
    if not config.trigger then
      vim.notify("No signature help available")
    end
    return
  end

  local message = M.get(M.kinds.signature)

  if config.trigger or not message:focus() then
    result.ft = vim.bo[ctx.bufnr].filetype
    result.message = message
    Signature.new(result):format()
    M.show(message, config.stay)
  end
end

function M.hover(_, result)
  if not (result and result.contents) then
    vim.notify("No information available")
    return
  end

  local message = M.get(M.kinds.hover)

  if not message:focus() then
    Format.format(message, result.contents)
    M.show(message)
  end
end

return M
