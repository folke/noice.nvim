local require = require("noice.util.lazy")

local Routes = require("noice.config.routes")

local M = {}

M.ns = vim.api.nvim_create_namespace("messages_highlights")

-- TODO: restructure config

---@class NoiceConfig
---@field history NoiceRouteConfig
---@field views table<string, NoiceViewOptions>
---@field status table<string, NoiceFilter>
---@field routes NoiceRouteConfig[]
M.defaults = {
  cmdline = {
    enabled = true, -- disable if you use native command line UI
    view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
    opts = { buf_options = { filetype = "vim" } }, -- enable syntax highlighting in the cmdline
    icons = {
      ["/"] = { icon = " ", hl_group = "DiagnosticWarn" },
      ["?"] = { icon = " ", hl_group = "DiagnosticWarn" },
      [":"] = { icon = " ", hl_group = "DiagnosticInfo", firstc = false },
    },
  },
  messages = {
    -- NOTE: If you enable noice messages UI, noice cmdline UI is enabled
    -- automatically. You cannot enable noice messages UI only.
    -- It is current neovim implementation limitation.  It may be fixed later.
    enabled = true, -- disable if you use native messages UI
  },
  popupmenu = {
    enabled = true, -- disable if you use something like cmp-cmdline
    ---@type 'nui'|'cmp'
    backend = "nui", -- backend to use to show regular cmdline completions
  },
  history = {
    -- options for the message history that you get with `:Noice`
    view = "split",
    opts = { enter = true, format = "details" },
    filter = { event = { "msg_show", "notify" }, ["not"] = { kind = { "search_count", "echo" } } },
  },
  notify = {
    -- Noice can be used as `vim.notify` so you can route any notification like other messages
    -- Notification messages have their level and other properties set.
    -- event is always "notify" and kind can be any log level as a string
    -- The default routes will forward notifications to nvim-notify
    -- Benefit of using Noice for this is the routing and consistent history view
    enabled = true,
  },
  lsp_progress = {
    enabled = false,
  },
  hacks = {
    -- due to https://github.com/neovim/neovim/issues/20416
    -- messages are resent during a redraw. Noice detects this in most cases, but
    -- some plugins (mostly vim plugns), can still cause loops.
    -- When a loop is detected, Noice exits.
    -- Enable this option to simply skip duplicate messages instead.
    skip_duplicate_messages = false,
  },
  throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
  views = {}, -- @see section on views
  routes = {}, -- @see section on routes
  status = {}, -- @see section on statusline components
  format = {}, -- @see section on formatting
  debug = false,
  log = vim.fn.stdpath("state") .. "/noice.log",
}

--- @type NoiceConfig
M.options = {}

function M.setup(options)
  options = options or {}

  M.options = vim.tbl_deep_extend("force", {}, M.defaults, {
    views = require("noice.config.views").defaults,
    status = require("noice.config.status").defaults,
    format = require("noice.config.format").defaults,
  }, options)

  M.options.routes = Routes.get(options.routes)

  require("noice.config.highlights").setup()

  if M.options.notify.enabled then
    vim.notify = require("noice").notify
  end
  if M.options.lsp_progress.enabled then
    require("noice.source.lsp").setup()
  end
end

return M
