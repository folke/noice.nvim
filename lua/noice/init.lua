local require = require("noice.util.lazy")

local Health = require("noice.util.health")
local Api = require("noice.api")

local M = {}

M.api = Api

---@param opts? NoiceConfig
function M.setup(opts)
  if not Health.check() then
    return
  end

  require("noice.config").setup(opts)
  require("noice.commands").setup()
  require("noice.message.router").setup()
  M.enable()

  Health.checker()
end

function M.disable()
  require("noice.message.router").disable()
  require("noice.ui").disable()
  require("noice.util.hacks").disable()
end

function M.enable()
  require("noice.util.hacks").enable()
  require("noice.ui").enable()
  require("noice.message.router").enable()
end

---@param msg string
---@param level number|string
---@param opts? table<string, any>
function M.notify(msg, level, opts)
  return require("noice.source.notify").notify(msg, level, opts)
end

return M
