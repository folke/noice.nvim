local require = require("noice.util.lazy")

local Message = require("noice.message")
local Manager = require("noice.message.manager")
local Router = require("noice.message.router")
local Util = require("noice.util")
local Msg = require("noice.ui.msg")

local M = {}

---@alias NotifyEvent "notify"
---@alias NotifyLevel "trace"|"debug"|"info"|"warn"|"error"|"off"

M._orig = nil

function M.enable()
  if vim.notify ~= M.notify then
    M._orig = vim.notify
    vim.notify = M.notify
  end
end

function M.disable()
  if M._orig then
    vim.notify = M._orig
    M._orig = nil
  end
end

function M.get_level(level)
  if type(level) == "string" then
    return level
  end
  for k, v in pairs(vim.log.levels) do
    if v == level then
      return k:lower()
    end
  end
  return "info"
end

---@param msg string
---@param level number|string
---@param opts? table<string, any>
function M.notify(msg, level, opts)
  level = M.get_level(level)
  local message = Message("notify", level, msg)
  message.opts = opts or {}
  message.level = level
  message.once = true
  Msg.check_clear()
  Manager.add(message)
  if Util.is_blocking() then
    Router.update()
  end
end

return M
