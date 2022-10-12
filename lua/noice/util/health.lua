local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")

local M = {}

M.checks = {}

---@param loaded? boolean
function M.check(loaded)
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

  if vim.go.lazyredraw then
    Util.warn_once(
      "You have enabled 'lazyredraw' (see `:h 'lazyredraw'`)\nThis is only meant to be set temporarily.\nYou'll experience issues using Noice."
    )
  end

  if loaded then
    if Config.options.notify.enabled and vim.notify ~= require("noice").notify then
      Util.error_once("`vim.notify` has been overwritten by another plugin?")
    end
  end

  return true
end

function M.checker()
  vim.defer_fn(function()
    M.check(true)
    M.checker()
  end, 1000)
end

return M
