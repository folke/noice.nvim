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
  ---@type NoiceRouteConfig[]
  local ret = {}

  for _, format in pairs(Config.options.cmdline.format) do
    table.insert(ret, {
      view = format.view,
      opts = format.opts,
      filter = { event = "cmdline", kind = format.kind },
    })
  end

  return vim.list_extend(ret, {
    {
      view = Config.options.cmdline.view,
      opts = Config.options.cmdline.opts,
      filter = { event = "cmdline" },
    },
    {
      view = "confirm",
      filter = {
        any = {
          { event = "msg_show", kind = "confirm" },
          { event = "msg_show", kind = "confirm_sub" },
          -- { event = "msg_show", kind = { "echo", "echomsg", "" }, before = true },
          -- { event = "msg_show", kind = { "echo", "echomsg" }, instant = true },
          -- { event = "msg_show", find = "E325" },
          -- { event = "msg_show", find = "Found a swap file" },
        },
      },
    },
    {
      view = Config.options.messages.view_history,
      filter = {
        any = {
          { event = "msg_history_show" },
          -- { min_height = 20 },
        },
      },
    },
    {
      view = Config.options.messages.view_search,
      filter = {
        event = "msg_show",
        kind = "search_count",
      },
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
      view = Config.options.messages.view,
      filter = {
        event = "msg_show",
        kind = { "", "echo", "echomsg" },
      },
      opts = { replace = true, merge = true, title = "Messages" },
    },
    {
      view = Config.options.messages.view_error,
      filter = { error = true },
      opts = { title = "Error" },
    },
    {
      view = Config.options.messages.view_warn,
      filter = { warning = true },
      opts = { title = "Warning" },
    },
    {
      view = Config.options.notify.view,
      filter = { event = "notify" },
      opts = { title = "Notify" },
    },
    {
      view = Config.options.notify.view,
      filter = {
        event = "noice",
        kind = { "stats", "debug" },
      },
      opts = { lang = "lua", replace = true, title = "Noice" },
    },
    {
      view = Config.options.lsp.hover.view,
      filter = { event = "lsp", kind = "hover" },
      opts = { lang = "markdown", replace = true },
    },
    {
      view = Config.options.lsp.progress.view,
      filter = { event = "lsp", kind = "progress" },
    },
  })
end

return M
