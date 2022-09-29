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
    filter = { event = "msg_show", ["not"] = { kind = { "search_count", "echo" } } },
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
    fancy_cmdline = {
      render = "popup",
      relative = "editor",
      focusable = true,
      position = {
        row = "50%",
        col = "50%",
      },
      size = {
        min_width = 60,
        width = "auto",
        height = "auto",
      },
      border = {
        style = "rounded",
        padding = { 0, 1, 0, 1 },
        text = {
          top = " Cmdline ",
        },
      },
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:DiagnosticInfo",
      },
      filter_options = {
        {
          filter = { event = "cmdline", find = "^%s*[/?]" },
          opts = {
            border = {
              text = {
                top = " Search ",
              },
            },
            win_options = {
              winhighlight = "Normal:Normal,FloatBorder:DiagnosticWarn",
            },
          },
        },
      },
    },
  },
  routes = {
    {
      view = "cmdline",
      filter = { event = "msg_show", kind = { "echo", "echomsg", "" }, blocking = true, max_height = 1 },
    },
    {
      view = "fancy_cmdline",
      filter = {
        any = {
          { event = "cmdline" },
          { event = "msg_show", kind = "confirm" },
          { event = "msg_show", kind = "confirm_sub" },
          { event = "msg_show", kind = { "echo", "echomsg", "" }, before_input = true },
          -- { event = "msg_show", kind = { "echo", "echomsg" }, instant = true },
          -- { event = "msg_show", find = "E325" },
          -- { event = "msg_show", find = "Found a swap file" },
        },
      },
      opts = {
        filter_options = {
          {
            -- Set filetype=vim only for cmdline events
            filter = { event = "cmdline" },
            opts = { buf_options = { filetype = "vim" } },
          },
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
