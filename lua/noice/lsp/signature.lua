local require = require("noice.util.lazy")

local Config = require("noice.config")
local Docs = require("noice.lsp.docs")
local Format = require("noice.lsp.format")
local Markdown = require("noice.text.markdown")
local NoiceText = require("noice.text")
local Util = require("noice.util")

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
  if Config.options.lsp.signature.auto_open.enabled then
    -- attach to existing buffers
    for _, client in ipairs((vim.lsp.get_clients or vim.lsp.get_active_clients)()) do
      for _, buf in ipairs(vim.lsp.get_buffers_by_client_id(client.id)) do
        M.on_attach(buf, client)
      end
    end

    -- attach to new buffers
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("noice_lsp_signature", { clear = true }),
      callback = function(args)
        if args.data ~= nil then
          M.on_attach(args.buf, vim.lsp.get_client_by_id(args.data.client_id))
        end
      end,
    })
  end
end

function M.get_char(buf)
  local current_win = vim.api.nvim_get_current_win()
  local win = buf == vim.api.nvim_win_get_buf(current_win) and current_win or vim.fn.bufwinid(buf)
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
    local triggerChars = client.server_capabilities.signatureHelpProvider.triggerCharacters
    local retriggerChars = client.server_capabilities.signatureHelpProvider.retriggerCharacters
    ---@type string[]
    local chars = {}
    if triggerChars then for _, c in ipairs(triggerChars) do chars[#chars + 1] = c end end
    if retriggerChars then for _, c in ipairs(retriggerChars) do chars[#chars + 1] = c end end
    if #chars > 0 then
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
      if Config.options.lsp.signature.auto_open.snipppets then
        vim.api.nvim_create_autocmd("ModeChanged", {
          buffer = buf,
          callback = function(ev)
            if ev.match == "v:s" then
              callback(ev)
            end
          end,
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
  if sig.activeParameter and sig.parameters and sig.parameters[sig.activeParameter + 1] then
    return sig.parameters[sig.activeParameter + 1]
  end
  if self.activeParameter and sig.parameters and sig.parameters[self.activeParameter + 1] then
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
    Format.format(self.message, sig.documentation, { ft = self.ft })
  end

  ---@type ParameterInformation[]
  local params = vim.tbl_filter(function(p)
    return p.documentation
  end, sig.parameters or {})

  local lines = {}
  if #params > 0 then
    for _, p in ipairs(sig.parameters) do
      if p.documentation then
        local pdoc = table.concat(Format.format_markdown(p.documentation or ""), "\n")
        local line = { "-" }
        if p.label then
          local label = p.label
          if type(label) == "table" then
            label = sig.label:sub(label[1] + 1, label[2])
          end

          line[#line + 1] = "`[" .. label .. "]`"
        end
        line[#line + 1] = pdoc
        lines[#lines + 1] = table.concat(line, " ")
      end
    end
  end
  Format.format(self.message, table.concat(lines, "\n"), { ft = self.ft })
end

function M:format()
  for s, sig in ipairs(self.signatures) do
    self:format_signature(s, sig)
  end
end

return M
