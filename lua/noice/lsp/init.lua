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
    require("noice.lsp.hover").setup()
  end

  if Config.options.lsp.signature.enabled then
    require("noice.lsp.signature").setup()
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

function M.scroll(delta)
  return require("noice.lsp.docs").scroll(delta)
end

function M.hover()
  ---@diagnostic disable-next-line: missing-parameter
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/hover", params, require("noice.lsp.hover").on_hover)
end

function M.signature()
  ---@diagnostic disable-next-line: missing-parameter
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/signatureHelp", params, require("noice.lsp.signature").on_signature)
end

function M.diagnostic()
  ---@diagnostic disable-next-line: missing-parameter
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/publishDiagnostics", params, require("noice.lsp.diagnostic").open_float)
end

return M
