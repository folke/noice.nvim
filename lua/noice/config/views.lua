local M = {}

-- TODO: fix single instance views

---@type table<string, NoiceViewOptions>
M.defaults = {
  popupmenu = {
    zindex = 65,
    position = "auto", -- when auto, then it will be positioned to the cmdline or cursor
    size = {
      width = "auto",
      -- min_width = 10,
    },
    win_options = {
      winhighlight = {
        Normal = "NoicePopupmenu", -- change to NormalFloat to make it look like other floats
        FloatBorder = "NoicePopupmenuBorder", -- border highlight
        CursorLine = "NoicePopupmenuSelected", -- used for highlighting the selected item
        PmenuMatch = "NoicePopupmenuMatch", -- used to highlight the part of the item that matches the input
      },
    },
    border = {
      padding = { 0, 1 },
    },
  },
  virtualtext = {
    backend = "virtualtext",
    format = { "{message}" },
    hl_group = "NoiceVirtualText",
  },
  notify = {
    backend = "notify",
    replace = true,
    format = "notify",
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
      winhighlight = { Normal = "NoiceSplit", FloatBorder = "NoiceSplitBorder" },
      wrap = true,
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
      winhighlight = { Normal = "NoiceSplit", FloatBorder = "NoiceSplitBorder" },
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
      winhighlight = { Normal = "NoicePopup", FloatBorder = "NoicePopupBorder" },
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
        Normal = "NoiceCmdline",
        IncSearch = "",
        Search = "",
      },
    },
  },
  mini = {
    backend = "mini",
    relative = "editor",
    align = "right",
    timeout = 2000,
    reverse = true,
    position = {
      row = -1,
      col = "100%",
      -- col = 0,
    },
    size = "auto",
    border = {
      style = "none",
    },
    zindex = 60,
    win_options = {
      winblend = 30,
      winhighlight = {
        Normal = "NoiceMini",
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
        Normal = "NoiceCmdlinePopup",
        FloatBorder = "NoiceCmdlinePopupBorder",
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
              FloatBorder = "NoiceCmdlinePopupSearchBorder",
              IncSearch = "",
              Search = "",
            },
          },
        },
      },
    },
  },
  confirm = {
    backend = "popup",
    relative = "editor",
    focusable = false,
    align = "center",
    enter = false,
    zindex = 60,
    format = { "{confirm}" },
    position = {
      row = "50%",
      col = "50%",
    },
    size = "auto",
    border = {
      style = "rounded",
      padding = { 0, 1, 0, 1 },
      text = {
        top = " Confirm ",
      },
    },
    win_options = {
      winhighlight = {
        Normal = "NoiceConfirm",
        FloatBorder = "NoiceConfirmBorder",
      },
    },
  },
}

return M
