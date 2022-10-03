# 💥 Noice _(Nice, Noise, Notice)_

Highly experimental plugin that completely replaces the UI for `messages`, `cmdline` and the `popupmenu`.

![image](https://user-images.githubusercontent.com/292349/193263220-791847b2-516c-4f23-9802-31dd6bec5f6a.png)

## ✨ Features

- 🌅 fully **configurable views** like [nvim-notify](https://github.com/rcarriga/nvim-notify), splits, popups, virtual text, ..
- 🔍 use **filters** to **route messages** to different views
- 🌈 message **highlights** are preserved in the views (like the colors of `:hi`)
- 📝 command output like [:messages](https://neovim.io/doc/user/message.html#:messages) is shown in normal buffers, which makes it much easier to work with
- 📚 `:Noice` command to show a full message history
- ⌨️  no more [:h more-prompt](https://neovim.io/doc/user/message.html#more-prompt)
- 💻 fully customizable **cmdline** with icons
- 💅 **syntax highlighting** for `vim` and `lua` on the **cmdline** 
- 🚥 **statusline** components

## ✅ Status

**WIP**

## ⚡️ Requirements

- Neovim >= 0.8.0
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim): used for proper rendering and multiple views
- [nvim-notify](https://github.com/rcarriga/nvim-notify): notification view
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp): used for rendering the regular cmdline completions or if you use [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline/)

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
  requires = {
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
    "hrsh7th/nvim-cmp",
    }
})
```

## ⚙️ Configuration

**noice.nvim** comes with the following defaults:

Check the [wiki](https://github.com/folke/noice.nvim/wiki/Configuration-Recipes) for configuration recipes.

```lua
{
  cmdline = {
    view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
    opts = { buf_options = { filetype = "vim" } }, -- enable syntax highlighting in the cmdline
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
  ---@type table<string, NoiceViewOptions>
  views = {}, -- @see the section on views below
  ---@type NoiceRouteConfig[]
  routes = {}, -- @see the section on routes below
  ---@type table<string, NoiceFilter>
  status = {}, --@see the section on statusline components below
}
```

### 🔍 Filters

**Noice** uses filters to route messages to specific views.

| Name         | Type                   | Description                                                                                                                            |
| ------------ | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| *cleared*    | `boolean`              | checks if the message is cleared, meaning it's in the history                                                                          |
| *mode*       | `string`               | checks if `vim.api.nvim_get_mode()` contains the given mode                                                                            |
| *blocking*   | `boolean`              | are we in blocking mode?                                                                                                               |
| *event*      | `string` or `string[]` | any of the events from `ext_messages` or `cmdline`. See [:h ui-messages](https://neovim.io/doc/user2/ui.html#_-message/dialog-events-) |
| *kind*       | `string` or `string[]` | any of the kinds from `ext_messages`. See [:h ui-messages](https://neovim.io/doc/user2/ui.html#_-message/dialog-events-)               |
| *error*      | `boolean`              | all error-like kinds from `ext_messages`                                                                                               |
| *warning*    | `boolean`              | all warning-like kinds from `ext_messages`                                                                                             |
| *find*       | `string`               | uses lua `string.find` to match the pattern                                                                                            |
| *min_height* | `number`               | minimum height of the message                                                                                                          |
| *max_height* | `number`               | maximum height of the message                                                                                                          |
| *not*        | `filter`               | checks wether the filter matches or not                                                                                                |
| *any*        | `filter[]`             | checks that at least one of the filters matches                                                                                        |

Example:

```lua
-- all messages over 10 lines, excluding echo and search_count
local filter = {
  event = "msg_show",
  min_height = 10,
  ["not"] = { kind = { "search_count", "echo" } },
}

```

### 🌅 Views

**Noice** comes with the following built-in renderers:
- **popup** powered by [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- **split** powered by [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- **notify** powered by [nvim-notify](https://github.com/rcarriga/nvim-notify)
- **virtualtext** shows the message as virtualtext (for example for `search_count`)

**Views** (`config.views`) are combinations of `render` methods and options.

**Noice** comes with the following built-in views with sane defaults:
- **notify** with default level and replaces existing notification by default
- **split** horizontal split
- **vsplit** vertical split
- **popup**
- **cmdline** bottom line, similar to the classic cmdline
- **cmdline_popup** fancy cmdline popup, with different styles according to the cmdline mode

Please refer to [noice.config.views](https://github.com/folke/noice.nvim/blob/main/lua/noice/config/views.lua) to see the options.

Any options passed to existing views in `config.views`, will override those options only.

You can configure completely new views and use them in custom routes.

Example:

```lua
-- override the default split view to always enter the split when it opens
require("noice").setup({
    views = {
        split = {
            enter = true
          }
      }
  })
```

**Nui Options**

See the Nui documentation for [Popup](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup)
and [Split](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/split).

Size & position can additionally be specified as `"auto"`, to use the message height and width.

**Notify Options**

- **title** title to be used for the notification
- **replace** `boolean` when true, messages routing to the same notify instance will replace existing messages instead of pushing a new notification every time

**Virtual Text Options**

Right now there's only an option to set the `hl_group` used to render the virtual text.


### 🚗 Routes

A **route** has a `filter`, `view` and optional `opts` attribute.
- **view**: one of the views (built-in or custom)
- **filter** a filter for messages matching this route
- **opts**: options for the view and the route

Route options can be any of the view options above, or one of:
- **skip**: messages matching this filter will be skipped and not shown in any views
- **stop** (`boolean`) defaults to `true`. When `false` and a route matches the filter,
then other routes can still process the message too. Useful if you want certain messages to be shown in multiple views.

Please refer to [noice.config.routes](https://github.com/folke/noice.nvim/blob/main/lua/noice/config/routes.lua) for an overview of the default routes.

**Routes** passed to `setup()` will be prepended to the default routes.

Example:

```lua
-- skip search_count messages instead of showing them as virtual text
require("noice").setup({
  routes = {
    {
      filter = { event = "msg_show", kind = "search_count" },
      opts = { skip = true },
    },
  },
})

-- always route any messages with more than 20 lines to the split view
require("noice").setup({
  routes = {
    {
      view = "split",
      filter = { event = "msg_show", min_height = 20 },
    },
  },
})
```

### 🚥 Statusline Components

**Noice** comes with the following statusline components:
* **ruler**
* **message**: last line of the last message (`event=show_msg`)
* **command**: `showcmd`
* **mode**: `showmode` (@recording messages)
* **search**: search count messages

See [noice.config.status](https://github.com/folke/noice.nvim/blob/main/lua/noice/config/status.lua) for the default config.

You can add custom statusline components in setup under the `status` key.

Statusline components have the following methods:
- **get**: gets the content of the message **without** highlights
- **get_hl**: gets the content of the message **with** highlights
- **has**: checks if the component is available

Example of configuring [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)

```lua
require("lualine").setup({
  sections = {
    lualine_x = {
      {
        require("noice.status").message.get_hl,
        cond = require("noice.status").message.has,
      },
      {
        require("noice.status").command.get,
        cond = require("noice.status").command.has,
        color = { fg = "#ff9e64" },
      },
      {
        require("noice.status").mode.get,
        cond = require("noice.status").mode.has,
        color = { fg = "#ff9e64" },
      },
      {
        require("noice.status").search.get,
        cond = require("noice.status").search.has,
        color = { fg = "#ff9e64" },
      },
    },
  },
})

```

## 🚀 Usage

* `:Noice` shows the message history
* `:Noice disable` disables **Noice**
* `:Noice enable` enables **Noice**
* `:Noice stats` shows debugging stats

## 🔥 Known Issues

**Noice** is using the new experimental `vim.ui_attach` API.

During setup, we apply a bunch of [Hacks](https://github.com/folke/noice.nvim/blob/main/lua/noice/hacks.lua)
to work around some of the current issues.

For more details, see https://github.com/folke/noice.nvim/issues/6
