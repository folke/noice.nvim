local require = require("noice.util.lazy")

local Routes = require("noice.config.routes")

local M = {}

M.ns = vim.api.nvim_create_namespace("messages_highlights")

---@class NoiceConfig
---@field history NoiceRouteConfig
---@field views table<string, NoiceViewOptions>
---@field routes NoiceRouteConfig[]
M.defaults = {
  debug = false,
  throttle = 1000 / 30,
  cmdline = {
    view = "cmdline_popup",
    opts = { buf_options = { filetype = "vim" } },
    menu = "popup", -- @type "popup" | "wild",
    icons = {
      ["/"] = { icon = " ", hl_group = "DiagnosticWarn" },
      ["?"] = { icon = " ", hl_group = "DiagnosticWarn" },
      [":"] = { icon = " ", hl_group = "DiagnosticInfo", firstc = false },
    },
  },
  history = {
    view = "split",
    opts = { enter = true },
    filter = { event = "msg_show", ["not"] = { kind = { "search_count", "echo" } } },
  },
  views = {},
  routes = {},
}

--- @type NoiceConfig
M.options = {}

function M.setup(options)
  options = options or {}

  M.options = vim.tbl_deep_extend("force", {}, M.defaults, {
    views = require("noice.config.views").defaults,
  }, options)

  M.options.routes = Routes.get(options.routes)
end

return M
