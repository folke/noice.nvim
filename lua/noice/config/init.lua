local require = require("noice.util.lazy")

local Routes = require("noice.config.routes")

local M = {}

M.ns = vim.api.nvim_create_namespace("messages_highlights")

---@class NoiceConfig
M.defaults = {
  cmdline = {
    enabled = true, -- enables the Noice cmdline UI
    view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
    view_search = "cmdline_popup_search", -- view for rendering the cmdline for search
    opts = { buf_options = { filetype = "vim" } }, -- enable syntax highlighting in the cmdline
    icons = {
      ["/"] = { icon = " ", hl_group = "NoiceCmdlineIconSearch" },
      ["?"] = { icon = " ", hl_group = "NoiceCmdlineIconSearch" },
      [":"] = { icon = " ", hl_group = "NoiceCmdlineIcon", firstc = false },
    },
  },
  messages = {
    -- NOTE: If you enable messages, then the cmdline is enabled automatically.
    -- This is a current Neovim limitation.
    enabled = true, -- enables the Noice messages UI
  },
  popupmenu = {
    enabled = true, -- enables the Noice popupmenu UI
    ---@type 'nui'|'cmp'
    backend = "nui", -- backend to use to show regular cmdline completions
  },
  ---@type NoiceRouteConfig
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
    -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
    -- See the section on formatting for more details on how to customize.
    --- @type NoiceFormat|string
    format = "lsp_progress",
    --- @type NoiceFormat|string
    format_done = "lsp_progress_done",
    throttle = 1000 / 30, -- frequency to update lsp progress message
  },
  throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
  ---@type NoiceConfigViews
  views = {}, ---@see section on views
  ---@type NoiceRouteConfig[]
  routes = {}, --- @see section on routes
  ---@type table<string, NoiceFilter>
  status = {}, --- @see section on statusline components
  ---@type NoiceFormatOptions
  format = {}, --- @see section on formatting
  hacks = {
    -- due to https://github.com/neovim/neovim/issues/20416
    -- messages are resent during a redraw. Noice detects this in most cases, but
    -- some plugins (mostly vim plugns), can still cause loops.
    -- When a loop is detected, Noice exits.
    -- Enable this option to simply skip duplicate messages instead.
    skip_duplicate_messages = false,
  },
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
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      require("noice.config.highlights").setup()
    end,
  })

  if M.options.lsp_progress.enabled then
    require("noice.source.lsp").setup()
  end
end

return M
