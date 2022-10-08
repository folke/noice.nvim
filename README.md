# 💥 Noice _(Nice, Noise, Notice)_

Highly experimental plugin that completely replaces the UI for `messages`, `cmdline` and the `popupmenu`.

![image](https://user-images.githubusercontent.com/292349/193263220-791847b2-516c-4f23-9802-31dd6bec5f6a.png)

## ✨ Features

- 🌅 fully **configurable views** like [nvim-notify](https://github.com/rcarriga/nvim-notify),
  splits, popups, virtual text, ..
- 🔍 use **filters** to **route messages** to different views
- 🌈 message **highlights** are preserved in the views (like the colors of `:hi`)
- 📝 command output like [:messages](https://neovim.io/doc/user/message.html#:messages)
  is shown in normal buffers, which makes it much easier to work with
- 📚 `:Noice` command to show a full message history
- ⌨️  no more [:h more-prompt](https://neovim.io/doc/user/message.html#more-prompt)
- 💻 fully customizable **cmdline** with icons
- 💅 **syntax highlighting** for `vim` and `lua` on the **cmdline**
- 🚥 **statusline** components
- 🔭 open message history in [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## ✅ Status

**WIP**

## ⚡️ Requirements

- Neovim >= 0.8.0
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim): used for proper rendering and multiple views
- [nvim-notify](https://github.com/rcarriga/nvim-notify): notification view

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
    }
})
```

## ⚙️ Configuration

**noice.nvim** comes with the following defaults:

Check the [wiki](https://github.com/folke/noice.nvim/wiki/Configuration-Recipes) for configuration recipes.

```lua
{
  cmdline = {
    enabled = true, -- disable if you use native command line UI
    view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
    opts = { buf_options = { filetype = "vim" } }, -- enable syntax highlighting in the cmdline
    icons = {
      ["/"] = { icon = " ", hl_group = "DiagnosticWarn" },
      ["?"] = { icon = " ", hl_group = "DiagnosticWarn" },
      [":"] = { icon = " ", hl_group = "DiagnosticInfo", firstc = false },
    },
  },
  messages = {
    -- NOTE: If you enable noice messages UI, noice cmdline UI is enabled
    -- automatically. You cannot enable noice messages UI only.
    -- It is current neovim implementation limitation.  It may be fixed later.
    enabled = true, -- disable if you use native messages UI
  },
  popupmenu = {
    enabled = true, -- disable if you use something like cmp-cmdline
    ---@type 'nui'|'cmp'
    backend = "nui", -- backend to use to show regular cmdline completions
    -- You can specify options for nui under `config.views.popupmenu`
  },
  history = {
    -- options for the message history that you get with `:Noice`
    view = "split",
    opts = { enter = true },
    filter = { event = "msg_show", ["not"] = { kind = { "search_count", "echo" } } },
  },
  notify = {
    -- Noice can be used as `vim.notify` so you can route any notification like other messages
    -- Notification messages have their level and other properties set.
    -- event is always "notify" and kind can be any log level as a string
    -- The default routes will forward notifications to nvim-notify
    -- Benefit of using Noice for this is the routing and consistent history view
    enabled = false,
  },
  throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
  ---@type table<string, NoiceViewOptions>
  views = {}, -- @see the section on views below
  ---@type NoiceRouteConfig[]
  routes = {}, -- @see the section on routes below
  ---@type table<string, NoiceFilter>
  status = {}, --@see the section on statusline components below
  ---@type NoiceFormatOptions
  format = {}, -- @see section on formatting
}
```

## 🔍 Filters

**Noice** uses filters to route messages to specific views.

| Name           | Type                   | Description                                                                                                                            |
| -------------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **cleared**    | `boolean`              | checks if the message is cleared, meaning it's in the history                                                                          |
| **mode**       | `string`               | checks if `vim.api.nvim_get_mode()` contains the given mode                                                                            |
| **blocking**   | `boolean`              | are we in blocking mode?                                                                                                               |
| **event**      | `string` or `string[]` | any of the events from `ext_messages` or `cmdline`. See [:h ui-messages](https://neovim.io/doc/user2/ui.html#_-message/dialog-events-) |
| **kind**       | `string` or `string[]` | any of the kinds from `ext_messages`. See [:h ui-messages](https://neovim.io/doc/user2/ui.html#_-message/dialog-events-)               |
| **error**      | `boolean`              | all error-like kinds from `ext_messages`                                                                                               |
| **warning**    | `boolean`              | all warning-like kinds from `ext_messages`                                                                                             |
| **find**       | `string`               | uses lua `string.find` to match the pattern                                                                                            |
| **min_height** | `number`               | minimum height of the message                                                                                                          |
| **max_height** | `number`               | maximum height of the message                                                                                                          |
| **not**        | `filter`               | checks wether the filter matches or not                                                                                                |
| **any**        | `filter[]`             | checks that at least one of the filters matches                                                                                        |

<details>
<summary>Example:</summary>

```lua
-- all messages over 10 lines, excluding echo and search_count
local filter = {
  event = "msg_show",
  min_height = 10,
  ["not"] = { kind = { "search_count", "echo" } },
}

```

</details>

## 🌅 Views

**Noice** comes with the following built-in backends:

- **popup**: powered by [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- **split**: powered by [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- **notify**: powered by [nvim-notify](https://github.com/rcarriga/nvim-notify)
- **virtualtext**: shows the message as virtualtext (for example for `search_count`)

A **View** (`config.views`) is a combination of a `backend` and options.
**Noice** comes with the following built-in views with sane defaults:

| View              | Backend    | Description                                                                        |
| ----------------- | ---------- | ---------------------------------------------------------------------------------- |
| **notify**        | `notify`   | _nvim-notify_ with `level=true`, `replace=true`, `merge=true`                      |
| **split**         | `split`    | horizontal split                                                                   |
| **vsplit**        | `split`    | vertical split                                                                     |
| **popup**         | `popup`    | simple popup                                                                       |
| **cmdline**       | `popup`    | bottom line, similar to the classic cmdline                                        |
| **cmdline_popup** | `popup`    | fancy cmdline popup, with different styles according to the cmdline mode           |
| **popupmenu**     | `nui.menu` | special view with the options used to render the popupmenu when backend is **nui** |

Please refer to [noice.config.views](https://github.com/folke/noice.nvim/blob/main/lua/noice/config/views.lua)
to see the options.
Any options passed to existing views in `config.views`, will override those options only.
You can configure completely new views and use them in custom routes.

<details>
<summary>Example:</summary>

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

</details>

### Nui Options

See the Nui documentation for [Popup](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup)
and [Split](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/split).

<table>
<tr><td>Option</td><td>Description</td></tr>
<tr>
<td> <b>size, position</b> </td>
<td>Size, position and their constituents can additionally be specified as <b>"auto"</b>, to use the message height and width.</td>
</tr>
<tr>
<td><b>win_options.winhighlight</b></td>
<td>
String or can also be a table like:

```lua
{
  win_options = {
    winhighlight = {
      Normal = "NormalFloat",
      FloatBorder = "FloatBorder"
    },
  }
}
```

</td>
</tr>
</table>

### Notify Options

| Option        | Type      | Default | Description                                                                                                                             |
| ------------- | --------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **title**     | `string`  | `nil`   | title to be used for the notification. Uses `Message.title` if available.                                                               |
| **replace**   | `boolean` | `true`  | when true, messages routing to the same notify instance will replace existing messages instead of pushing a new notification every time |
| **merge**     | `boolean` | `true`  | Merge messages into one Notification or create separate notifications                                                                   |
| **level**     | `number\|string`    |  `"info"` notification level. Uses `Message.level` if available.                                                                        |

### Virtual Text Options

Right now there's only an option to set the `hl_group` used to render the virtual text.

## 🎨 Formatting

Formatting options can be specified with `config.format`.
For a list of the defaults, please refer to [config.format](https://github.com/folke/noice.nvim/blob/main/lua/noice/config/format.lua)

**Noice** includes the following formatters:

- **level**: message level with optional `icon` and `hl_group` per level
- **text**: any text with optional `hl_group`
- **title**: message title with optional `hl_group`
- **event**: message event with optional `hl_group`
- **kind**: message kind with optional `hl_group`
- **date**: formatted date with optional date format string
- **message**: message content itself with optional `hl_group` to override message highlights
- **confirm**: only useful for `confirm` messages. Will format the choices as buttons.

Formatters are used in `format` definitions. **Noice** includes the following built-in formats:

```lua
{
  -- default format
  default = { "{level} ", "{title} ", "{message}" },
  -- default format for vim.notify views
  notify = { "{message}" },
  -- default format for the history
  details = {
    "{level} ",
    "{date} ",
    "{event}",
    { "{kind}", before = { ".", hl_group = "Comment" } },
    " ",
    "{title} ",
    "{message}",
  },
  telescope = ..., -- formatter used to display telescope results
  telescope_preview = ..., -- formatter used to preview telescope results
}
```

Text before/after the formatter or in the before/after options, will only be rendered if the formatter itself rendered something.

The `format` view option, can be either a `string` (one of the built-in formats), or a table with a custom format definition.

## 🚗 Routes

A **route** has a `filter`, `view` and optional `opts` attribute.

- **view**: one of the views (built-in or custom)
- **filter** a filter for messages matching this route
- **opts**: options for the view and the route

Route options can be any of the view options above, or one of:

| Option   | Type      | Default | Description                                                                                                                                                          |
| -------- | --------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **skip** | `boolean` | `false` | messages matching this filter will be skipped and not shown in any views                                                                                             |
| **stop** | `boolean` | `true`  | When `false` and a route matches the filter, then other routes can still process the message too. Useful if you want certain messages to be shown in multiple views. |

Please refer to [noice.config.routes](https://github.com/folke/noice.nvim/blob/main/lua/noice/config/routes.lua)
for an overview of the default routes.
**Routes** passed to `setup()` will be prepended to the default routes.

<details>
<summary>Example</summary>

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

</details>

## 🚥 Statusline Components

**Noice** comes with the following statusline components:

- **ruler**
- **message**: last line of the last message (`event=show_msg`)
- **command**: `showcmd`
- **mode**: `showmode` (@recording messages)
- **search**: search count messages

See [noice.config.status](https://github.com/folke/noice.nvim/blob/main/lua/noice/config/status.lua) for the default config.

You can add custom statusline components in setup under the `status` key.

Statusline components have the following methods:

- **get**: gets the content of the message **without** highlights
- **get_hl**: gets the content of the message **with** highlights
- **has**: checks if the component is available

<details>
<summary>Example of configuring <a href="https://github.com/nvim-lualine/lualine.nvim">lualine.nvim</a></summary>

```lua
require("lualine").setup({
  sections = {
    lualine_x = {
      {
        require("noice").api.statusline.message.get_hl,
        cond = require("noice").api.statusline.message.has,
      },
      {
        require("noice").api.statusline.command.get,
        cond = require("noice").api.statusline.command.has,
        color = { fg = "#ff9e64" },
      },
      {
        require("noice").api.statusline.mode.get,
        cond = require("noice").api.statusline.mode.has,
        color = { fg = "#ff9e64" },
      },
      {
        require("noice").api.statusline.search.get,
        cond = require("noice").api.statusline.search.has,
        color = { fg = "#ff9e64" },
      },
    },
  },
})

```

</details>

## 🔭 Telescope

In order to use **Noice** in **Telescope**, you can either do `:Noice telescope`, or register the extension and use `:Telescope noice`.
The results panel is formatted using `config.format.formatters.telescope`. The preview is formatted with `config.format.formatters.telescope_preview`

```lua
require("telescope").load_extension("noice")
```

## 🚀 Usage

- `:Noice` shows the message history  
- `:Noice disable` disables **Noice**
- `:Noice enable` enables **Noice**
- `:Noice stats` shows debugging stats
- `:Noice telescope` opens message history in Telescope

## 🔥 Known Issues

**Noice** is using the new experimental `vim.ui_attach` API, so issues are to be expected.
During setup, we apply a bunch of [Hacks](https://github.com/folke/noice.nvim/blob/main/lua/noice/hacks.lua)
to work around some of the current issues.
For more details, see this [tracking issue](https://github.com/folke/noice.nvim/issues/6)
