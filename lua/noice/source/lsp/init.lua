local require = require("noice.util.lazy")

local Manager = require("noice.message.manager")
local Config = require("noice.config")
local Format = require("noice.source.lsp.format")
local Util = require("noice.util")

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
    vim.lsp.handlers["textDocument/hover"] = Util.protect(M.hover)
  end
  if Config.options.lsp.progress.enabled then
    require("noice.source.lsp.progress").setup()
  end
end

---@param message NoiceMessage
function M.auto_close(message)
  local open = true
  message.opts.timeout = 100
  message.opts.keep = function()
    return open
  end

  local group = vim.api.nvim_create_augroup("noice_lsp_" .. message.id, {
    clear = true,
  })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertCharPre" }, {
    group = group,
    callback = function()
      if not Util.buf_has_message(vim.api.nvim_get_current_buf(), message) then
        pcall(vim.api.nvim_del_augroup_by_id, group)
        Manager.remove(message)
        open = false
      end
    end,
  })
end

---@param message NoiceMessage
function M.try_enter(message)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if Util.buf_has_message(buf, message) then
      local win = vim.fn.bufwinid(buf)
      if win ~= -1 then
        vim.api.nvim_set_current_win(win)
        vim.wo[win].conceallevel = 0
        return true
      end
    end
  end
end

function M.hover(_, result)
  if not (result and result.contents) then
    vim.notify("No information available")
    return
  end

  local message = Format.format(result.contents, "hover")
  if not M.try_enter(message) then
    M.auto_close(message)
    Manager.add(message)
  end
end

return M
