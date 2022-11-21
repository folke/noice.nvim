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

  local uis = vim.api.nvim_list_uis()
  for _, ui in ipairs(uis) do
    local ok = true
    for _, ext in ipairs({ "ext_multigrid", "ext_cmdline", "ext_popupmenu", "ext_messages" }) do
      if ui[ext] then
        ok = false
        log.error(
          "You're using a GUI that uses " .. ext .. ". Noice can't work when the GUI has " .. ext .. " enabled."
        )
      end
    end
    if ok then
      if ui.chan == 0 then
        log.ok("You're not using a GUI")
      else
        log.ok("You're using a GUI that should work ok")
      end
    end
  end

  if vim.go.lazyredraw then
    if not Config.is_running() then
      log.warn(
        "You have enabled 'lazyredraw' (see `:h 'lazyredraw'`)\nThis is only meant to be set temporarily.\nYou'll experience issues using Noice."
      )
    end
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
      for _, ft in ipairs({ "vim", "regex", "lua", "bash", "markdown", "markdown_inline" }) do
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
    ---@type {opt:string[], opt_str?:string, handler:fun(), handler_str:string}
    local checks = {
      {
        opt = "notify",
        enabled = Config.options.notify.enabled,
        handler = vim.notify,
        handler_str = "vim.notify",
      },
      {
        opt = "lsp.hover",
        enabled = Config.options.lsp.hover.enabled,
        handler = vim.lsp.handlers["textDocument/hover"],
        handler_str = 'vim.lsp.handlers["textDocument/hover"]',
      },
      {
        opt = "lsp.signature",
        enabled = Config.options.lsp.signature.enabled,
        handler = vim.lsp.handlers["textDocument/signatureHelp"],
        handler_str = 'vim.lsp.handlers["textDocument/signatureHelp"]',
      },
      {
        opt = "lsp.message",
        enabled = Config.options.lsp.message,
        handler = vim.lsp.handlers["window/showMessage"],
        handler_str = 'vim.lsp.handlers["window/showMessage"]',
      },
      {
        opt = 'lsp.override["vim.lsp.util.convert_input_to_markdown_lines"]',
        enabled = Config.options.lsp.override["vim.lsp.util.convert_input_to_markdown_lines"],
        handler = vim.lsp.util.convert_input_to_markdown_lines,
        handler_str = "vim.lsp.util.convert_input_to_markdown_lines",
      },
      {
        opt = 'lsp.override["vim.lsp.util.stylize_markdown"]',
        enabled = Config.options.lsp.override["vim.lsp.util.stylize_markdown"],
        handler = vim.lsp.util.stylize_markdown,
        handler_str = "vim.lsp.util.stylize_markdown",
      },
    }

    local ok, mod = pcall(_G.require, "cmp.entry")
    table.insert(checks, {
      opt = 'lsp.override["cmp.entry.get_documentation"]',
      enabled = Config.options.lsp.override["cmp.entry.get_documentation"],
      handler = ok and mod.get_documentation,
      handler_str = "cmp.entry.get_documentation",
    })

    for _, check in ipairs(checks) do
      if check.handler then
        if check.enabled then
          local source = M.get_source(check.handler)
          if source.plugin ~= "noice.nvim" then
            log.error(([[`%s` has been overwritten by another plugin?

Either disable the other plugin or set `config.%s.enabled = false` in your **Noice** config.
  - plugin: %s
  - file: %s
  - line: %s]]):format(check.handler_str, check.opt, source.plugin, source.source, source.line))
          else
            log.ok(("`%s` is set to **Noice**"):format(check.handler_str))
          end
        elseif opts.checkhealth then
          log.warn("`" .. check.handler_str .. "` is not configured to be handled by **Noice**")
        end
      end
    end
  end

  return true
end

function M.get_source(fn)
  local info = debug.getinfo(fn, "S")
  local source = info.source:sub(2)
  ---@class FunSource
  local ret = {
    line = info.linedefined,
    source = source,
    plugin = "unknown",
  }
  if source:find("noice") then
    ret.plugin = "noice.nvim"
  elseif source:find("/runtime/lua/") then
    ret.plugin = "nvim"
  else
    local opt = source:match("/pack/[^%/]-/opt/([^%/]-)/")
    local start = source:match("/pack/[^%/]-/start/([^%/]-)/")
    ret.plugin = opt or start or "unknown"
  end
  return ret
end
M.check({ checkhealth = false })

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
