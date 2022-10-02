local require = require("noice.util.lazy")

local Config = require("noice.config")

local M = {}

---@param routes? NoiceRouteConfig[]
function M.get(routes)
  ---@type NoiceRouteConfig[]
  local ret = {}

  -- add custom routes
  vim.list_extend(ret, routes or {})

  -- add default routes
  vim.list_extend(ret, M.defaults())
  return ret
end

---@return NoiceRouteConfig[]
function M.defaults()
  return {
    {
      view = Config.options.cmdline.view,
      opts = Config.options.cmdline.opts,
      filter = { event = "cmdline" },
    },
    {
      view = "cmdline",
      filter = { event = "msg_show", kind = { "echo", "echomsg", "" }, blocking = true, max_height = 1 },
    },
    {
      view = "cmdline_popup",
      filter = {
        any = {
          { event = "msg_show", kind = "confirm" },
          { event = "msg_show", kind = "confirm_sub" },
          { event = "msg_show", kind = { "echo", "echomsg", "" }, before_input = true },
          -- { event = "msg_show", kind = { "echo", "echomsg" }, instant = true },
          -- { event = "msg_show", find = "E325" },
          -- { event = "msg_show", find = "Found a swap file" },
        },
      },
    },
    {
      view = "split",
      filter = {
        any = {
          { event = "msg_history_show" },
          -- { min_height = 20 },
        },
      },
    },
    {
      view = "virtualtext",
      filter = {
        event = "msg_show",
        kind = "search_count",
      },
      opts = { hl_group = "DiagnosticVirtualTextInfo" },
    },
    {
      filter = {
        any = {
          { event = { "msg_showmode", "msg_showcmd", "msg_ruler" } },
          { event = "msg_show", kind = "search_count" },
        },
      },
      opts = { skip = true },
    },
    {
      view = "notify",
      filter = {
        event = "noice",
        kind = { "stats", "debug" },
      },
      opts = { buf_options = { filetype = "lua" }, replace = true },
    },
    {
      view = "notify",
      filter = {
        error = true,
      },
      opts = { level = vim.log.levels.ERROR, replace = false, title = "Error" },
    },
    {
      view = "notify",
      filter = {
        event = "msg_show",
        kind = "wmsg",
      },
      opts = { level = vim.log.levels.WARN, replace = false, title = "Warning" },
    },
    {
      view = "notify",
      filter = {},
    },
  }
end

return M
