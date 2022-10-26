local require = require("noice.util.lazy")

local Manager = require("noice.message.manager")
local Config = require("noice.config")
local Format = require("noice.source.lsp.format")
local Util = require("noice.util")
local Message = require("noice.message")
local Signature = require("noice.source.lsp.signature")

local M = {}

---@alias LspEvent "lsp"
M.event = "lsp"

---@enum LspKind
M.kinds = {
  progress = "progress",
  hover = "hover",
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
  M.hover = Util.protect(M.hover)
  if Config.options.lsp.hover.enabled then
    vim.lsp.handlers["textDocument/hover"] = M.hover
  end

  M.signature = Util.protect(M.signature)
  if Config.options.lsp.signature.enabled then
    vim.lsp.handlers["textDocument/signatureHelp"] = M.signature
  end

  if Config.options.lsp.signature.auto_open then
    require("noice.source.lsp.signature").setup()
  end

  if Config.options.lsp.progress.enabled then
    require("noice.source.lsp.progress").setup()
  end
end

function M.scroll(delta)
  for _, kind in ipairs({ M.kinds.hover, M.kinds.signature }) do
    local message = M.get(kind)
    local win = message:win()
    if win then
      Util.nui.scroll(win, delta)
      return
    end
  end
end

---@param message NoiceMessage
function M.augroup(message)
  return "noice_lsp_" .. message.id
end

---@param message NoiceMessage
function M.close(message)
  pcall(vim.api.nvim_del_augroup_by_name, M.augroup(message))
  message.opts.keep = function()
    return false
  end
  Manager.remove(message)
end

---@param message NoiceMessage
function M.auto_close(message)
  message.opts.timeout = 100
  message.opts.keep = function()
    return true
  end

  local group = vim.api.nvim_create_augroup(M.augroup(message), {
    clear = true,
  })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertCharPre" }, {
    group = group,
    callback = function()
      if not message:on_buf(vim.api.nvim_get_current_buf()) then
        M.close(message)
      end
    end,
  })
end

---@param message NoiceMessage
function M.close_others(message)
  for _, m in pairs(M._messages) do
    if m ~= message then
      M.close(m)
    end
  end
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
  M.close_others(message)

  if config.trigger or not message:focus() then
    result.ft = vim.bo[ctx.bufnr].filetype
    result.message = message
    Signature.new(result):format()
    M.auto_close(message)
    Manager.add(message)
  end
end

function M.hover(_, result)
  if not (result and result.contents) then
    vim.notify("No information available")
    return
  end

  local message = M.get(M.kinds.hover)
  M.close_others(message)
  if not message:focus() then
    Format.format(message, result.contents)
    M.auto_close(message)
    Manager.add(message)
  end
end

return M
