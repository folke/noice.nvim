local M = {}

---@type table<string, NoiceViewOptions>
M.defaults = {
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
  cmdline_popup = {
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
}

return M
