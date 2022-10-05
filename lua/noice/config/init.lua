local require = require("noice.util.lazy")

local Routes = require("noice.config.routes")

local M = {}

M.ns = vim.api.nvim_create_namespace("messages_highlights")

---@class NoiceConfig
---@field history NoiceRouteConfig
---@field views table<string, NoiceViewOptions>
---@field status table<string, NoiceFilter>
---@field routes NoiceRouteConfig[]
M.defaults = {
  cmdline = {
    view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
    opts = { buf_options = { filetype = "vim" } }, -- enable syntax highlighting in the cmdline
    icons = {
      ["/"] = { icon = " ", hl_group = "DiagnosticWarn" },
      ["?"] = { icon = " ", hl_group = "DiagnosticWarn" },
      [":"] = { icon = " ", hl_group = "DiagnosticInfo", firstc = false },
    },
  },
  popupmenu = {
    enabled = true, -- disable if you use something like cmp-cmdline
    ---@type 'nui'|'cmp'
    backend = "nui", -- backend to use to show regular cmdline completions
  },
  history = {
    -- options for the message history that you get with `:Noice`
    view = "split",
    opts = { enter = true },
    filter = { event = { "msg_show", "notify" }, ["not"] = { kind = { "search_count", "echo" } } },
  },
  throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
  views = {}, -- @see section on views
  routes = {}, -- @see section on routes
  status = {}, -- @see section on statusline components
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
  }, options)

  M.options.routes = Routes.get(options.routes)
end

return M
