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

---@class lsp.ProgressParams
---@field token integer|string	provided by the client or server
---@field value MsgInfo			the progress data

---@alias WorkDoneProgressKind 'begin'|'report'|'end'

---@class MsgInfo
---@field id string?					unique id associated with the message
---@field kind WorkDoneProgressKind?	process message with respect to the kind
---@field title string?					briefly inform about the progress operation
---@field message string?				more detailed associated progress message
---@field percentage integer?			progress percentage to display [0, 100]

---@param name string the fake lsp client name
---@param msg MsgInfo?
---@return string?
function M.progress_msg(name, msg)
  local msg_token = ""

  if msg and msg.id then
    if not (string.sub(msg.id, 1, #name) == name) then
      return -- invalid msg.id
    end
    msg_token = string.sub(msg.id, #name + 2)
  else
    msg_token = os.time() .. "." .. math.random(1e8)
  end

  local msg_value = vim.tbl_deep_extend("force", {
    id = name .. "." .. msg_token,
    kind = "begin",
  }, msg or {})

  M.progress({
    client_name = name,
    result = {
      token = msg_token,
      value = msg_value,
    },
  })

  return msg_value.id
end

---@param id string
function M.progress_msg_end(id)
  local message = M._progress[id]
  if not message then
    return
  end

  local msg = message.opts.progress
  M.progress_msg(msg.client, {
    id = id,
    kind = "end",
    title = msg.title,
    message = msg.message,
    percentage = msg.percentage,
  })
end

---@param data {client_id: integer?, client_name: string?, result: lsp.ProgressParams}
function M.progress(data)
  local client_id = data.client_id
  local client = { name = data.client_name }
  local result = data.result

  -- provide either client_id or client_name(nonlsp, id will be present)
  local id = result.value.id
  if not id then
    if not client_id then
      return
    end
    id = client_id .. "." .. result.token
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
