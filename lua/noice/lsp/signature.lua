local require = require("noice.util.lazy")

local NoiceText = require("noice.text")
local Format = require("noice.lsp.format")
local Markdown = require("noice.text.markdown")
local Config = require("noice.config")
local Util = require("noice.util")
local Docs = require("noice.lsp.docs")

---@class SignatureInformation
---@field label string
---@field documentation? string|MarkupContent
---@field parameters? ParameterInformation[]
---@field activeParameter? integer

---@class ParameterInformation
---@field label string|{[1]:integer, [2]:integer}
---@field documentation? string|MarkupContent

---@class SignatureHelpContext
---@field triggerKind SignatureHelpTriggerKind
---@field triggerCharacter? string
---@field isRetrigger boolean
---@field activeSignatureHelp? SignatureHelp

---@class SignatureHelp
---@field signatures SignatureInformation[]
---@field activeSignature? integer
---@field activeParameter? integer
---@field ft? string
---@field message NoiceMessage
local M = {}
M.__index = M

---@enum SignatureHelpTriggerKind
M.trigger_kind = {
  invoked = 1,
  trigger_character = 2,
  content_change = 3,
}

function M.setup()
  vim.lsp.handlers["textDocument/signatureHelp"] = M.on_signature

  if Config.options.lsp.signature.auto_open.enabled then
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("noice_lsp_signature", { clear = true }),
      callback = function(args)
        M.on_attach(args.buf, vim.lsp.get_client_by_id(args.data.client_id))
      end,
    })
  end
end

function M.get_char(buf)
  local win = vim.fn.bufwinid(buf)
  local cursor = vim.api.nvim_win_get_cursor(win == -1 and 0 or win)
  local row = cursor[1] - 1
  local col = cursor[2]
  local _, lines = pcall(vim.api.nvim_buf_get_text, buf, row, 0, row, col, {})
  local line = vim.trim(lines and lines[1] or "")
  return line:sub(-1, -1)
end

---@param result SignatureHelp
function M.on_signature(_, result, ctx, config)
  config = config or {}
  if not (result and result.signatures) then
    if not config.trigger then
      vim.notify("No signature help available")
    end
    return
  end

  local message = Docs.get("signature")

  if config.trigger or not message:focus() then
    result.ft = vim.bo[ctx.bufnr].filetype
    result.message = message
    M.new(result):format()
    if message:is_empty() then
      if not config.trigger then
        vim.notify("No signature help available")
      end
      return
    end
    Docs.show(message, config.stay)
  end
end
M.on_signature = Util.protect(M.on_signature)

function M.on_attach(buf, client)
  if client.server_capabilities.signatureHelpProvider then
    ---@type string[]
    local chars = client.server_capabilities.signatureHelpProvider.triggerCharacters
    if chars and #chars > 0 then
      local callback = M.check(buf, chars, client.offset_encoding)
      if Config.options.lsp.signature.auto_open.luasnip then
        vim.api.nvim_create_autocmd("User", {
          pattern = "LuasnipInsertNodeEnter",
          callback = callback,
        })
      end
      if Config.options.lsp.signature.auto_open.trigger then
        vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP", "InsertEnter" }, {
          buffer = buf,
          callback = callback,
        })
      end
    end
  end
end

function M.check(buf, chars, encoding)
  encoding = encoding or "utf-16"
  return Util.debounce(Config.options.lsp.signature.auto_open.throttle, function(_event)
    if vim.api.nvim_get_current_buf() ~= buf then
      return
    end

    if vim.tbl_contains(chars, M.get_char(buf)) then
      local params = vim.lsp.util.make_position_params(0, encoding)
      vim.lsp.buf_request(buf, "textDocument/signatureHelp", params, function(err, result, ctx)
        M.on_signature(err, result, ctx, {
          trigger = true,
          stay = function()
            return vim.tbl_contains(chars, M.get_char(buf))
          end,
        })
      end)
    end
  end)
end

---@param help SignatureHelp
function M.new(help)
  return setmetatable(help, M)
end

function M:active_parameter(sig_index)
  if self.activeSignature and self.signatures[self.activeSignature + 1] and sig_index ~= self.activeSignature + 1 then
    return
  end
  local sig = self.signatures[sig_index]
  if sig.activeParameter and sig.parameters[sig.activeParameter + 1] then
    return sig.parameters[sig.activeParameter + 1]
  end
  if self.activeParameter and sig.parameters[self.activeParameter + 1] then
    return sig.parameters[self.activeParameter + 1]
  end
  return sig.parameters and sig.parameters[1] or nil
end

---@param sig SignatureInformation
---@param param ParameterInformation
function M:format_active_parameter(sig, param)
  local label = param.label
  if type(label) == "string" then
    local from = sig.label:find(label, 1, true)
    if from then
      self.message:append(NoiceText("", {
        hl_group = "LspSignatureActiveParameter",
        col = from - 1,
        length = vim.fn.strlen(label),
      }))
    end
  else
    self.message:append(NoiceText("", {
      hl_group = "LspSignatureActiveParameter",
      col = label[1],
      length = label[2] - label[1],
    }))
  end
end

--- dddd
-- function M:format_signature(boo) end

---@param sig SignatureInformation
---@overload fun() # goooo
function M:format_signature(sig_index, sig)
  if sig_index ~= 1 then
    self.message:newline()
    self.message:newline()
    Markdown.horizontal_line(self.message)
    self.message:newline()
  end

  local count = self.message:height()
  self.message:append(sig.label)
  self.message:append(NoiceText.syntax(self.ft, self.message:height() - count))
  local param = self:active_parameter(sig_index)
  if param then
    self:format_active_parameter(sig, param)
  end
  self.message:newline()

  if sig.documentation then
    Markdown.horizontal_line(self.message)
    Format.format(self.message, sig.documentation)
  end
end

function M:format()
  for s, sig in ipairs(self.signatures) do
    self:format_signature(s, sig)
  end
end

return M
