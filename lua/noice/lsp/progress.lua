local require = require("noice.util.lazy")

local Message = require("noice.message")
local Manager = require("noice.message.manager")
local Router = require("noice.message.router")
local Format = require("noice.text.format")
local Config = require("noice.config")
local Util = require("noice.util")

local M = {}

---@type table<string, NoiceMessage>
M._progress = {}
M._running = false

---@param data {client_id: integer, result: lsp.ProgressParams}
function M.progress(data)
  local client_id = data.client_id
  local result = data.result
  local id = client_id .. "." .. result.token

  local message = M._progress[id]
  if not message then
    local client = vim.lsp.get_client_by_id(client_id)
    -- should not happen, but it does for some reason
    if not client then
      return
    end
    message = Message("lsp", "progress")
    message.opts.progress = {
      client_id = client_id,
      ---@type string
      client = client and client.name or ("lsp-" .. client_id),
    }
    M._progress[id] = message
  end

  message.opts.progress = vim.tbl_deep_extend("force", message.opts.progress, result.value)
  message.opts.progress.id = id

  if result.value.kind == "end" then
    if message.opts.progress.percentage then
      message.opts.progress.percentage = 100
    end
    vim.defer_fn(function()
      M.close(id)
    end, 100)
  end

  M.update()
end

function M.close(id)
  local message = M._progress[id]
  if message then
    M.update()
    Router.update()
    Manager.remove(message)
    M._progress[id] = nil
  end
end

function M._update()
  if not vim.tbl_isempty(M._progress) then
    for id, message in pairs(M._progress) do
      local client = vim.lsp.get_client_by_id(message.opts.progress.client_id)
      if not client then
        M.close(id)
      end
      if message.opts.progress.kind == "end" then
        Manager.add(Format.format(message, Config.options.lsp.progress.format_done))
      else
        Manager.add(Format.format(message, Config.options.lsp.progress.format))
      end
    end
    return
  end
end

function M.update()
  error("should never be called")
end

function M.setup()
  M.update = Util.interval(Config.options.lsp.progress.throttle, M._update, {
    enabled = function()
      return not vim.tbl_isempty(M._progress)
    end,
  })

  -- Neovim >= 0.10.0
  local ok = pcall(vim.api.nvim_create_autocmd, "LspProgress", {
    group = vim.api.nvim_create_augroup("noice_lsp_progress", { clear = true }),
    callback = function(event)
      M.progress(event.data)
    end,
  })

  -- Neovim < 0.10.0
  if not ok then
    local orig = vim.lsp.handlers["$/progress"]
    vim.lsp.handlers["$/progress"] = function(...)
      local result = select(2, ...)
      local ctx = select(3, ...)
      Util.try(function()
        M.progress({ client_id = ctx.client_id, result = result })
      end)
      orig(...)
    end
  end
end

return M
