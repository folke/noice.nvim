local require = require("noice.util.lazy")

local Util = require("noice.util")
local Api = require("noice.api")

local M = {}

M.api = Api

---@param opts? NoiceConfig
function M.setup(opts)
  if vim.fn.has("nvim-0.8.0") ~= 1 then
    Util.error("Noice needs Neovim >= 0.8.0")
    -- require("noice.util").error("Noice needs Neovim >= 0.9.0 (nightly)")
    return
  end
  if vim.g.neovide then
    Util.error("Noice doesn't work with Neovide. Please see #17")
    return
  end
  if not Util.module_exists("notify") then
    Util.error("Noice needs nvim-notify to work properly")
    return
  end
  if vim.g.lazyredraw then
    Util.warn(
      "You have enabled lazyredraw (see `:h 'lazyredraw'`)\nThis is only meant to be set temporarily.\nYou'll experience issues using Noice."
    )
  end
  require("noice.config").setup(opts)
  require("noice.commands").setup()
  require("noice.message.router").setup()
  M.enable()
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
