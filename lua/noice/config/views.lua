local M = {}

---@type table<string, NoiceViewOptions>
M.defaults = {
  popupmenu = {
    zindex = 65,
    position = "auto", -- when auto, then it will be positioned to the cmdline or cursor
    win_options = {
      winhighlight = {
        Normal = "Pmenu", -- change to NormalFloat to make it look like other floats
        FloatBorder = "FloatBorder", -- border highlight
        CursorLine = "PmenuSel", -- used for highlighting the selected item
        PmenuMatch = "Special", -- used to highlight the part of the item that matches the input
      },
    },
  },
  notify = {
    backend = "notify",
    level = vim.log.levels.INFO,
    replace = true,
  },
  split = {
    backend = "split",
    enter = false,
    relative = "editor",
    position = "bottom",
    size = "20%",
    close = {
      keys = { "q", "<esc>" },
    },
    win_options = {
      winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" },
    },
  },
  vsplit = {
    backend = "split",
    enter = false,
    relative = "editor",
    position = "right",
    size = "20%",
    close = {
      keys = { "q", "<esc>" },
    },
    win_options = {
      winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" },
    },
  },
  popup = {
    backend = "popup",
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
      winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" },
    },
  },
  cmdline = {
    backend = "popup",
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
      winhighlight = {
        Normal = "MsgArea",
        IncSearch = "",
        Search = "",
      },
    },
  },
  cmdline_popup = {
    backend = "popup",
    relative = "editor",
    focusable = false,
    enter = false,
    zindex = 60,
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
      winhighlight = {
        Normal = "Normal",
        FloatBorder = "DiagnosticInfo",
        IncSearch = "",
        Search = "",
      },
      cursorline = false,
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
            winhighlight = {
              Normal = "Normal",
              FloatBorder = "DiagnosticWarn",
              IncSearch = "",
              Search = "",
            },
          },
        },
      },
    },
  },
}

return M
