local M = {}

M.ns = vim.api.nvim_create_namespace("messages_highlights")

---@class NoiceConfig
---@field history NoiceRouteConfig
---@field views table<string, NoiceViewOptions>
---@field routes NoiceRouteConfig[]
M.defaults = {
  debug = true,
  throttle = 1000 / 30,
  cmdline = {
    enabled = true,
    menu = "popup", -- @type "popup" | "wild",
    icons = {
      ["/"] = { icon = " ", hl_group = "DiagnosticWarn" },
      ["?"] = { icon = " ", hl_group = "DiagnosticWarn" },
      [":"] = { icon = " ", hl_group = "DiagnosticInfo", firstc = false },
    },
  },
  history = {
    view = "split",
    opts = {
      enter = true,
    },
    filter = { event = "msg_show" },
  },
  views = {
    notify = {
      render = "notify",
      level = vim.log.levels.INFO,
      replace = true,
    },
    split = {
      render = "split",
      enter = false,
      relative = "editor",
      position = "bottom",
      size = "20%",
      close = {
        keys = { "q", "<esc>" },
      },
      win_options = {
        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
      },
    },
    popup = {
      render = "popup",
      close = {
        events = { "BufLeave" },
        keys = { "q", "<esc>" },
      },
      enter = true,
      border = {
        style = "single",
      },
      position = "50%",
      size = {
        width = "80%",
        height = "60%",
      },
      win_options = {
        winhighlight = "Normal:Float,FloatBorder:FloatBorder",
      },
    },
    cmdline = {
      render = "popup",
      relative = "editor",
      position = {
        row = "100%",
        col = 0,
      },
      size = {
        height = "auto",
        width = "100%",
      },
      border = {
        style = "none",
      },
      win_options = {
        winhighlight = "Normal:MsgArea",
      },
    },
  },
  routes = {
    -- TODO: add something like the below
    -- ,{
    --   view = "split",
    --   filter = { event = "msg_show" },
    --   opts = { propagate = true, auto_open = false },
    -- }
    -- {
    --   view = "split",
    --   filter = { event = "msg_show" },
    --   opts = { stop = false, history = true },
    -- },
    {
      view = "cmdline",
      filter = { event = "cmdline" },
      opts = {
        buf_options = {
          filetype = "vim",
        },
      },
    },
    {
      view = "cmdline",
      filter = {
        any = {
          { event = "msg_show", kind = "confirm" },
          { event = "msg_show", kind = "confirm_sub" },
          { event = "msg_show", kind = { "echo", "echomsg" }, instant = true },
          -- { event = "msg_show", find = "E325" },
          -- { event = "msg_show", find = "Found a swap file" },
        },
      },
      opts = {},
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
    },
    {
      view = "nop", -- use statusline components instead
      filter = {
        any = {
          { event = { "msg_showmode", "msg_showcmd", "msg_ruler" } },
          { event = "msg_show", kind = "search_count" },
        },
      },
    },
    {
      view = "notify",
      filter = {
        error = true,
      },
      opts = { level = vim.log.levels.ERROR, replace = false },
    },
    {
      view = "notify",
      filter = {
        event = "msg_show",
        kind = "wmsg",
      },
      opts = { level = vim.log.levels.WARN, replace = false },
    },
    {
      view = "notify",
      filter = {},
    },
  },
}

--- @type NoiceConfig
M.options = {}

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
end

return M
