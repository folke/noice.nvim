local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")
local Lsp = require("noice.lsp")

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
    log.warn("Noice may not work correctly with Neovide. Please see #17")
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

    local _, ts = pcall(require, "nvim-treesitter.parsers")

    if ts then
      log.ok("**treesitter-nvim** is installed")
      for _, ft in ipairs({ "vim", "regex", "lua", "bash", "markdown" }) do
        if ts.has_parser(ft) then
          log.ok("**TreeSitter " .. ft .. "** parser is installed")
        else
          log.warn(
            "**TreeSitter "
              .. ft
              .. "** parser is not installed. Highlighting of the cmdline for "
              .. ft
              .. " might be broken"
          )
        end
      end
    else
      log.warn("**treesitter-nvim** not installed. Highlighting of the cmdline might be wrong")
    end
  end

  if Config.is_running() then
    if Config.options.notify.enabled then
      if vim.notify ~= require("noice.source.notify").notify then
        log.error("`vim.notify` has been overwritten by another plugin?")
      else
        log.ok("`vim.notify` is set to **Noice**")
      end
    else
      if opts.checkhealth then
        log.warn("Noice `vim.notify` is disabled")
      end
    end

    if Config.options.lsp.hover.enabled then
      if vim.lsp.handlers["textDocument/hover"] ~= Lsp.hover then
        log.error([[`vim.lsp.handlers["textDocument/hover"]` has been overwritten by another plugin?]])
      else
        log.ok([[`vim.lsp.handlers["textDocument/hover"]` is handled by **Noice**]])
      end
    else
      if opts.checkhealth then
        log.warn([[`vim.lsp.handlers["textDocument/hover"]` is not handled by **Noice**]])
      end
    end

    if Config.options.lsp.signature.enabled then
      if vim.lsp.handlers["textDocument/signatureHelp"] ~= Lsp.signature then
        log.error([[`vim.lsp.handlers["textDocument/signatureHelp"]` has been overwritten by another plugin?]])
      else
        log.ok([[`vim.lsp.handlers["textDocument/signatureHelp"]` is handled by **Noice**]])
      end
    else
      if opts.checkhealth then
        log.warn([[`vim.lsp.handlers["textDocument/signatureHelp"]` is not handled by **Noice**]])
      end
    end
  end

  return true
end

M.checker = Util.interval(1000, function()
  if Config.is_running() then
    M.check({ checkhealth = false })
  end
end, {
  enabled = function()
    return Config.is_running()
  end,
})

return M
