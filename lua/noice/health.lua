local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")

local M = {}

M.checks = {}

M.log = {
  ---@class NoiceHealthLog
  checkhealth = {
    start = function(msg)
      vim.health.report_start(msg or "noice.nvim")
    end,
    info = function(msg, ...)
      vim.health.report_info(msg:format(...))
    end,
    ok = function(msg, ...)
      vim.health.report_ok(msg:format(...))
    end,
    warn = function(msg, ...)
      vim.health.report_warn(msg:format(...))
    end,
    error = function(msg, ...)
      vim.health.report_error(msg:format(...))
    end,
  },
  ---@type NoiceHealthLog
  notify = {
    start = function(msg) end,
    info = function(msg, ...)
      Util.info(msg:format(...))
    end,
    ok = function(msg, ...) end,
    warn = function(msg, ...)
      Util.warn_once(msg:format(...))
    end,
    error = function(msg, ...)
      Util.error_once(msg:format(...))
    end,
  },
}

---@param opts? {checkhealth?: boolean}
function M.check(opts)
  opts = opts or {}
  opts.checkhealth = opts.checkhealth == nil and true or opts.checkhealth

  local log = opts.checkhealth and M.log.checkhealth or M.log.notify

  log.start()

  if vim.fn.has("nvim-0.8.0") ~= 1 then
    log.error("Noice needs Neovim >= 0.8.0")
    -- require("noice.util").error("Noice needs Neovim >= 0.9.0 (nightly)")
    if not opts.checkhealth then
      return
    end
  else
    log.ok("**Neovim** >= 0.8.0")
    if opts.checkhealth and vim.fn.has("nvim-0.9.0") ~= 1 then
      log.warn("**Neovim** 0.9.0 (nightly) is recommended, since it fixes some issues related to `vim.ui_attach`")
    end
  end

  if vim.g.neovide then
    log.error("Noice doesn't work with Neovide. Please see #17")
    if not opts.checkhealth then
      return
    end
  else
    log.ok("Not running inside **Neovide**")
  end

  if vim.go.lazyredraw then
    log.warn(
      "You have enabled 'lazyredraw' (see `:h 'lazyredraw'`)\nThis is only meant to be set temporarily.\nYou'll experience issues using Noice."
    )
  else
    log.ok("**vim.go.lazyredraw** is not enabled")
  end

  if opts.checkhealth then
    if not Util.module_exists("notify") then
      log.warn("Noice needs nvim-notify for routes using the `notify` view")
      if not opts.checkhealth then
        return
      end
    else
      log.ok("**nvim-notify** is installed")
    end

    if vim.o.shortmess:find("S") then
      log.warn(
        "You added `S` to `vim.opt.shortmess`. Search count messages will not be handled by Noice. So no virtual text for search count."
      )
    end
  end

  if Config.is_running() then
    if Config.options.notify.enabled and vim.notify ~= require("noice.source.notify").notify then
      log.error("`vim.notify` has been overwritten by another plugin?")
    else
      log.ok("`vim.notify` is set to **Noice**")
    end
  end

  return true
end

M.checker = Util.interval(1000, function()
  if require("noice")._running then
    M.check({ checkhealth = false })
  end
end, {
  enabled = function()
    return Config.is_running()
  end,
})

return M
