# 💥 Noice _(Nice, Noise, Notice)_

Highly experimental plugin that completely replaces the UI for `messages`, `cmdline` and the `popupmenu`.

![image](https://user-images.githubusercontent.com/292349/193263220-791847b2-516c-4f23-9802-31dd6bec5f6a.png)

## ✨ Features

- 🌅 fully **configurable views** like [nvim-notify](https://github.com/rcarriga/nvim-notify), splits, popups, virtual text, ..
- 🔍 use **filters** to **route messages** to different views
- 🌈 message **highlights** are preserved in the views (like the colors of `:hi`)
- 📝 [:messages](https://neovim.io/doc/user/message.html#:messages) are shown in normal buffers, which makes them much easier to work with
- 📚 `:Noice` command to show a full message history
- 🚦 no more [:h more-prompt](https://neovim.io/doc/user/message.html#more-prompt)
- 💻 fully customizable **cmdline** with icons
- 💅 **syntax highlighting** for `vim` and `lua` on the **cmdline** 

## ✅ Status

**WIP**

## ⚡️ Requirements

- Neovim >= 0.9.0 or nightly
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim): used for proper rendering and multiple views
- [nvim-notify](https://github.com/rcarriga/nvim-notify): notification view
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp): we use some internal views for rendering the cmdline completion popup. 

## 📦 Installation

Install the plugin with your preferred package manager:

```lua
-- Packer
use({
  "folke/noice.nvim",
  event = "VimEnter",
  config = function()
    require("noice").setup()
  end,
})
```

## ⚙️ Configuration

**noice.nvim** comes with the following defaults:

> TODO: add proper documentation for config, views, routes, options

```lua
{
  debug = false,
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
---
```

## 🔥 Known Issues

**Noice** is using the new experimental `vim.ui_attach` API.

During setup, we apply a bunch of [Hacks](https://github.com/folke/noice.nvim/blob/main/lua/noice/hacks.lua)
to work around some of the current issues.

- during a **Search**, we temporarily set `conceallevel=0`, to make sure *IncSearch* is rendering correctly
- `vim.fn.getchar`, `vim.fn.getcharstr`, `vim.fn.inputlist` are wrapped, so we know **blocking input** is coming
- any **redraw** command is intercepted, to make sure we stop processing any messages during redraw
- when in `blocking` mode, we use a slightly fix for `nvim-notify` to make realtime notifications possible

