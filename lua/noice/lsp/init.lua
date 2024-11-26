local require = require("noice.util.lazy")

local Config = require("noice.config")

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

function M.setup()
  if Config.options.lsp.hover.enabled then
    vim.lsp.buf.hover = M.hover
  end

  if Config.options.lsp.signature.enabled then
    require("noice.lsp.signature").setup()
    vim.lsp.buf.signature_help = M.signature
  end

  if Config.options.lsp.message.enabled then
    require("noice.lsp.message").setup()
  end

  if Config.options.lsp.progress.enabled then
    require("noice.lsp.progress").setup()
  end

  local overrides = vim.tbl_filter(
    ---@param v boolean
    function(v)
      return v
    end,
    Config.options.lsp.override
  )

  if #overrides > 0 then
    require("noice.lsp.override").setup()
  end
end

local function make_position_params()
  if vim.fn.has("nvim-0.11") == 1 then
    return function(client)
      return vim.lsp.util.make_position_params(nil, client.offset_encoding)
    end
  else
    ---@diagnostic disable-next-line: missing-parameter
    return vim.lsp.util.make_position_params()
  end
end

function M.scroll(delta)
  return require("noice.lsp.docs").scroll(delta)
end

function M.hover()
  local params = make_position_params()
  vim.lsp.buf_request(0, "textDocument/hover", params, require("noice.lsp.hover").on_hover)
end

function M.signature()
  local params = make_position_params()
  vim.lsp.buf_request(0, "textDocument/signatureHelp", params, require("noice.lsp.signature").on_signature)
end

return M
