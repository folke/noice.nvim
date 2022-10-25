local require = require("noice.util.lazy")

local Manager = require("noice.message.manager")
local Config = require("noice.config")
local Format = require("noice.source.lsp.format")

local M = {}

---@alias LspEvent "lsp"
M.event = "lsp"

---@enum LspKind
M.kinds = {
  progress = "progress",
  hover = "hover",
}

function M.setup()
  if Config.options.lsp.hover.enabled then
    vim.lsp.handlers["textDocument/hover"] = M.hover
  end
  if Config.options.lsp.progress.enabled then
    require("noice.source.lsp.progress").setup()
  end
end

---@param message NoiceMessage
function M.close_on_move(message)
  local open = true
  message.opts.timeout = 100
  message.opts.keep = function()
    return open
  end
  vim.api.nvim_create_autocmd("CursorMoved", {
    callback = function()
      open = false
    end,
    once = true,
  })
end

function M.hover(_, result)
  if not (result and result.contents) then
    vim.notify("No information available")
    return
  end

  local message = Format.format(result.contents, "hover")
  M.close_on_move(message)
  Manager.add(message)
end

return M
