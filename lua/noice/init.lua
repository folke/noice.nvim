local require = require("noice.util.lazy")

local Health = require("noice.health")
local Api = require("noice.api")
local Config = require("noice.config")

local M = {}

M.api = Api
M._running = false

---@param opts? NoiceConfig
function M.setup(opts)
  if not Health.check({ checkhealth = false, loaded = false }) then
    return
  end

  require("noice.util").try(function()
    require("noice.config").setup(opts)
    require("noice.commands").setup()
    require("noice.message.router").setup()
    M.enable()
  end)
end

function M.disable()
  M._running = false
  if Config.options.notify.enabled then
    require("noice.source.notify").disable()
  end
  require("noice.message.router").disable()
  require("noice.ui").disable()
  require("noice.util.hacks").disable()
end

function M.enable()
  M._running = true
  if Config.options.notify.enabled then
    require("noice.source.notify").enable()
  end
  require("noice.util.hacks").enable()
  require("noice.ui").enable()
  require("noice.message.router").enable()
  Health.checker()
end

---@param msg string
---@param level number|string
---@param opts? table<string, any>
function M.notify(msg, level, opts)
  return require("noice.source.notify").notify(msg, level, opts)
end

return M
