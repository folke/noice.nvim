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
- ❓ **statusline** components

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

> TODO: add proper documentation for views, routes, options

```lua
{
  cmdline = {
    view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
    opts = { buf_options = { filetype = "vim" } }, -- enable syntax highlighting in the cmdline
    menu = "popup", -- @type "popup" | "wild", -- what style of popupmenu do you want to use?
    icons = {
      ["/"] = { icon = " ", hl_group = "DiagnosticWarn" },
      ["?"] = { icon = " ", hl_group = "DiagnosticWarn" },
      [":"] = { icon = " ", hl_group = "DiagnosticInfo", firstc = false },
    },
  },
  history = {
    -- options for the message history that you get with `:Noice`
    view = "split",
    opts = { enter = true },
    filter = { event = "msg_show", ["not"] = { kind = { "search_count", "echo" } } },
  },
  throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
  views = {}, -- @see the section on views below
  routes = {}, -- @see the section on routes below
}
```

### 🔍 Filters

### 🌅 Views

### 🚗 Routes

## 🚀 Usage

* `:Noice` shows the message history
* `:Noice disable` disables **Noice**
* `:Noice enable` enables **Noice**
* `:Noice stats` shows debugging stats

## 🔥 Known Issues

**Noice** is using the new experimental `vim.ui_attach` API.

During setup, we apply a bunch of [Hacks](https://github.com/folke/noice.nvim/blob/main/lua/noice/hacks.lua)
to work around some of the current issues.

- we use fake cursors to draw where the real cursor should be. [An API](https://github.com/neovim/neovim/issues/20309) for the cursor position will be added in Neovim 0.9.0
- during a **Search**, we temporarily set `conceallevel=0`, to make sure *IncSearch* is rendering correctly
- `vim.fn.getchar`, `vim.fn.getcharstr`, `vim.fn.inputlist` are wrapped, so we know **blocking input** is coming
- any **redraw** command is intercepted, to make sure we stop processing any messages during redraw
- when in `blocking` mode, we use a slightly fix for `nvim-notify` to make realtime notifications possible

