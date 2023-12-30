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

math.randomseed(os.time())
local maxinteger = math.maxinteger or 9223372036854775807

---@param title string
---@param info string?
---@param percentage integer?
---@return string?
function M.progress_without_lsp(title, info, percentage)
  return M.progress({
    client_id = nil, -- disable lsp check with this set to nil
    client_name = title, -- title as fake lsp client name
    result = {
      -- generate random token with bit size about `63 * 2`, should be enough
      token = math.random(maxinteger) .. "." .. math.random(maxinteger),
      value = { percentage = percentage },
    },
  })
end

function M.progress_finish(id)
  local message = M._progress[id]
  if not message then
    return
  end

  message.opts.progress.kind = "end"

  if message.opts.progress.percentage then
    message.opts.progress.percentage = 100
  end

  vim.defer_fn(function()
    M.close(id)
  end, 100)

  M.update()
end

---@param data {client_id: integer?, client_name: string?, result: lsp.ProgressParams}
---@return string?
function M.progress(data)
  local client_id = data.client_id
  local client = { name = data.client_name }
  local result = data.result

  -- provide either client_id or client
  local id = client_id or client.name
  if id then
    id = id .. "." .. result.token
  else
    return
  end

  local message = M._progress[id]
  if not message then
    if client_id then
      client = vim.lsp.get_client_by_id(client_id)
      -- should not happen, but it does for some reason
      if not client then
        return
      end
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

  return id
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
      if message.opts.progress.client_id then
        local client = vim.lsp.get_client_by_id(message.opts.progress.client_id)
        if not client then
          M.close(id)
        end
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
