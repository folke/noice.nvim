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
- ⌨️ no more [:h more-prompt](https://neovim.io/doc/user/message.html#more-prompt)
- 💻 fully customizable **cmdline** with icons
- 💅 **syntax highlighting** for `vim` and `lua` on the **cmdline**
- 🚥 **statusline** components
- 🔭 open message history in [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## 🔥 Status

**Noice** is using the new experimental `vim.ui_attach` API, so issues are to be expected.
It is highly recommended to use Neovim nightly, since a bunch of issues have already been fixed upstream.
Check this [tracking issue](https://github.com/folke/noice.nvim/issues/6) for a list of known issues.

## ⚡️ Requirements

- Neovim >= 0.8.0 **_(nightly highly recommended)_**
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim): used for proper rendering and multiple views
- [nvim-notify](https://github.com/rcarriga/nvim-notify): notification view _**(optional)**_
- a [Nerd Font](https://www.nerdfonts.com/) **_(optional)_**
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter/) **_(optional, but highly recommended)_**
  used for highlighting the cmdline and lsp docs. Make sure to install the parsers for
  `vim`, `regex`, `lua`, `bash`, `markdown` and `markdown_inline`

## 📦 Installation

Install the plugin with your preferred package manager:

```lua
-- lazy.nvim
{
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    -- add any options here
  },
  dependencies = {
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    "MunifTanjim/nui.nvim",
    -- OPTIONAL:
    --   `nvim-notify` is only needed, if you want to use the notification view.
    --   If not available, we use `mini` as the fallback
    "rcarriga/nvim-notify",
    }
}
```

Suggested setup:

```lua
require("noice").setup({
  lsp = {
    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true,
    },
  },
  -- you can enable a preset for easier configuration
  presets = {
    bottom_search = true, -- use a classic bottom cmdline for search
    command_palette = true, -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
})
```

It's a good idea to run `:checkhealth noice` after installing to check for common issues.

<details><summary>vim-plug</summary>

```vim
" vim-plug
call plug#begin()
  Plug 'folke/noice.nvim'
  Plug 'MunifTanjim/nui.nvim'
call plug#end()

lua require("noice").setup()

```

</details>

## ⚙️ Configuration

**noice.nvim** comes with the following defaults:

Check the [wiki](https://github.com/folke/noice.nvim/wiki/Configuration-Recipes) for configuration recipes.

```lua
{
  cmdline = {
    enabled = true, -- enables the Noice cmdline UI
    view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
    opts = {}, -- global options for the cmdline. See section on views
    ---@type table<string, CmdlineFormat>
    format = {
      -- conceal: (default=true) This will hide the text in the cmdline that matches the pattern.
      -- view: (default is cmdline view)
      -- opts: any options passed to the view
      -- icon_hl_group: optional hl_group for the icon
      -- title: set to anything or empty string to hide
      cmdline = { pattern = "^:", icon = "", lang = "vim" },
      search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
      search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
      filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
      lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
      help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
      input = {}, -- Used by input()
      -- lua = false, -- to disable a format, set to `false`
    },
  },
  messages = {
    -- NOTE: If you enable messages, then the cmdline is enabled automatically.
    -- This is a current Neovim limitation.
    enabled = true, -- enables the Noice messages UI
    view = "notify", -- default view for messages
    view_error = "notify", -- view for errors
    view_warn = "notify", -- view for warnings
    view_history = "messages", -- view for :messages
    view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
  },
  popupmenu = {
    enabled = true, -- enables the Noice popupmenu UI
    ---@type 'nui'|'cmp'
    backend = "nui", -- backend to use to show regular cmdline completions
    ---@type NoicePopupmenuItemKind|false
    -- Icons for completion item kinds (see defaults at noice.config.icons.kinds)
    kind_icons = {}, -- set to `false` to disable icons
  },
  -- default options for require('noice').redirect
  -- see the section on Command Redirection
  ---@type NoiceRouteConfig
  redirect = {
    view = "popup",
    filter = { event = "msg_show" },
  },
  -- You can add any custom commands below that will be available with `:Noice command`
  ---@type table<string, NoiceCommand>
  commands = {
    history = {
      -- options for the message history that you get with `:Noice`
      view = "split",
      opts = { enter = true, format = "details" },
      filter = {
        any = {
          { event = "notify" },
          { error = true },
          { warning = true },
          { event = "msg_show", kind = { "" } },
          { event = "lsp", kind = "message" },
        },
      },
    },
    -- :Noice last
    last = {
      view = "popup",
      opts = { enter = true, format = "details" },
      filter = {
        any = {
          { event = "notify" },
          { error = true },
          { warning = true },
          { event = "msg_show", kind = { "" } },
          { event = "lsp", kind = "message" },
        },
      },
      filter_opts = { count = 1 },
    },
    -- :Noice errors
    errors = {
      -- options for the message history that you get with `:Noice`
      view = "popup",
      opts = { enter = true, format = "details" },
      filter = { error = true },
      filter_opts = { reverse = true },
    },
  },
  notify = {
    -- Noice can be used as `vim.notify` so you can route any notification like other messages
    -- Notification messages have their level and other properties set.
    -- event is always "notify" and kind can be any log level as a string
    -- The default routes will forward notifications to nvim-notify
    -- Benefit of using Noice for this is the routing and consistent history view
    enabled = true,
    view = "notify",
  },
  lsp = {
    progress = {
      enabled = true,
      -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
      -- See the section on formatting for more details on how to customize.
      --- @type NoiceFormat|string
      format = "lsp_progress",
      --- @type NoiceFormat|string
      format_done = "lsp_progress_done",
      throttle = 1000 / 30, -- frequency to update lsp progress message
      view = "mini",
    },
    override = {
      -- override the default lsp markdown formatter with Noice
      ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
      -- override the lsp markdown formatter with Noice
      ["vim.lsp.util.stylize_markdown"] = false,
      -- override cmp documentation with Noice (needs the other options to work)
      ["cmp.entry.get_documentation"] = false,
    },
    hover = {
      enabled = true,
      silent = false, -- set to true to not show a message if hover is not available
      view = nil, -- when nil, use defaults from documentation
      ---@type NoiceViewOptions
      opts = {}, -- merged with defaults from documentation
    },
    signature = {
      enabled = true,
      auto_open = {
        enabled = true,
        trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
        luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
        throttle = 50, -- Debounce lsp signature help request by 50ms
      },
      view = nil, -- when nil, use defaults from documentation
      ---@type NoiceViewOptions
      opts = {}, -- merged with defaults from documentation
    },
    message = {
      -- Messages shown by lsp servers
      enabled = true,
      view = "notify",
      opts = {},
    },
    -- defaults for hover and signature help
    documentation = {
      view = "hover",
      ---@type NoiceViewOptions
      opts = {
        lang = "markdown",
        replace = true,
        render = "plain",
        format = { "{message}" },
        win_options = { concealcursor = "n", conceallevel = 3 },
      },
    },
  },
  markdown = {
    hover = {
      ["|(%S-)|"] = vim.cmd.help, -- vim help links
      ["%[.-%]%((%S-)%)"] = require("noice.util").open, -- markdown links
    },
    highlights = {
      ["|%S-|"] = "@text.reference",
      ["@%S+"] = "@parameter",
      ["^%s*(Parameters:)"] = "@text.title",
      ["^%s*(Return:)"] = "@text.title",
      ["^%s*(See also:)"] = "@text.title",
      ["{%S-}"] = "@parameter",
    },
  },
  health = {
    checker = true, -- Disable if you don't want health checks to run
  },
  smart_move = {
    -- noice tries to move out of the way of existing floating windows.
    enabled = true, -- you can disable this behaviour here
    -- add any filetypes here, that shouldn't trigger smart move.
    excluded_filetypes = { "cmp_menu", "cmp_docs", "notify" },
  },
  ---@type NoicePresets
  presets = {
    -- you can enable a preset by setting it to true, or a table that will override the preset config
    -- you can also add custom presets that you can enable/disable with enabled=true
    bottom_search = false, -- use a classic bottom cmdline for search
    command_palette = false, -- position the cmdline and popupmenu together
    long_message_to_split = false, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
  throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
  ---@type NoiceConfigViews
  views = {}, ---@see section on views
  ---@type NoiceRouteConfig[]
  routes = {}, --- @see section on routes
  ---@type table<string, NoiceFilter>
  status = {}, --- @see section on statusline components
  ---@type NoiceFormatOptions
  format = {}, --- @see section on formatting
}
```

<details>
<summary>If you don't want to use a Nerd Font, you can replace the icons with Unicode symbols.</summary>

```lua
  require("noice").setup({
    cmdline = {
      format = {
        cmdline = { icon = ">" },
        search_down = { icon = "🔍⌄" },
        search_up = { icon = "🔍⌃" },
        filter = { icon = "$" },
        lua = { icon = "☾" },
        help = { icon = "?" },
      },
    },
    format = {
      level = {
        icons = {
          error = "✖",
          warn = "▼",
          info = "●",
        },
      },
    },
    popupmenu = {
      kind_icons = false,
    },
    inc_rename = {
      cmdline = {
        format = {
          IncRename = { icon = "⟳" },
        },
      },
    },
  })
```

</details>

## 🔍 Filters

**Noice** uses filters to route messages to specific views.

| Name           | Type                   | Description                                                                                                              |
| -------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **any**        | `filter[]`             | checks that at least one of the filters matches                                                                          |
| **blocking**   | `boolean`              | are we in blocking mode?                                                                                                 |
| **cleared**    | `boolean`              | checks if the message is cleared, meaning it's in the history                                                            |
| **cmdline**    | `boolean` or `string`  | checks if the message was generated by executing a cmdline. When `string`, then it is used as a pattern                  |
| **error**      | `boolean`              | all error-like kinds from `ext_messages`                                                                                 |
| **event**      | `string` or `string[]` | any of the events from `ext_messages` or `cmdline`. See [:h ui-messages](https://neovim.io/doc/user/ui.html#ui-messages) |
| **find**       | `string`               | uses lua `string.find` to match the pattern                                                                              |
| **has**        | `boolean`              | checks if the message is exists, meaning it's in the history                                                             |
| **kind**       | `string` or `string[]` | any of the kinds from `ext_messages`. See [:h ui-messages](https://neovim.io/doc/user/ui.html#ui-messages)               |
| **max_height** | `number`               | maximum height of the message                                                                                            |
| **max_length** | `number`               | maximum length of the message (total width of all the lines)                                                             |
| **max_width**  | `number`               | maximum width of the message                                                                                             |
| **min_height** | `number`               | minimum height of the message                                                                                            |
| **min_length** | `number`               | minimum length of the message (total width of all the lines)                                                             |
| **min_width**  | `number`               | minimum width of the message                                                                                             |
| **mode**       | `string`               | checks if `vim.api.nvim_get_mode()` contains the given mode                                                              |
| **not**        | `filter`               | checks wether the filter matches or not                                                                                  |
| **warning**    | `boolean`              | all warning-like kinds from `ext_messages`                                                                               |

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
- **mini**: similar to [notifier.nvim](https://github.com/vigoux/notifier.nvim) & [fidget.nvim](https://github.com/j-hui/fidget.nvim)
- **notify_send**: generate a desktop notification

A **View** (`config.views`) is a combination of a `backend` and options.
**Noice** comes with the following built-in views with sane defaults:

| View               | Backend    | Description                                                                        |
| ------------------ | ---------- | ---------------------------------------------------------------------------------- |
| **notify**         | `notify`   | _nvim-notify_ with `level=nil`, `replace=false`, `merge=false`                     |
| **split**          | `split`    | horizontal split                                                                   |
| **vsplit**         | `split`    | vertical split                                                                     |
| **popup**          | `popup`    | simple popup                                                                       |
| **mini**           | `mini`     | minimal view, by default bottom right, right-aligned                               |
| **cmdline**        | `popup`    | bottom line, similar to the classic cmdline                                        |
| **cmdline_popup**  | `popup`    | fancy cmdline popup, with different styles according to the cmdline mode           |
| **cmdline_output** | `split`    | split used by `config.presets.cmdline_output_to_split`                             |
| **messages**       | `split`    | split used for `:messages`                                                         |
| **confirm**        | `popup`    | popup used for `confirm` events                                                    |
| **hover**          | `popup`    | popup used for lsp signature help and hover                                        |
| **popupmenu**      | `nui.menu` | special view with the options used to render the popupmenu when backend is **nui** |

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
      enter = true,
    },
  },
})
```

</details>

> All built-in Noice views have the filetype `noice`

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
<td> <b>scrollbar</b> </td>
<td>Set to <code>false</code> to hide the scrollbar.</td>
</tr>
<tr>
</table>

### Notify Options

| Option      | Type             | Default          | Description                                                                                                                             |
| ----------- | ---------------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **title**   | `string`         | `"Notification"` | title to be used for the notification. Uses `Message.title` if available.                                                               |
| **replace** | `boolean`        | `false`          | when true, messages routing to the same notify instance will replace existing messages instead of pushing a new notification every time |
| **merge**   | `boolean`        | `false`          | Merge messages into one Notification or create separate notifications                                                                   |
| **level**   | `number\|string` | `nil`            | notification level. Uses `Message.level` if available.                                                                                  |

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
- **cmdline**: will render the cmdline in the message that generated the message.
- **progress**: progress bar used by lsp progress
- **spinner**: spinners used by lsp progress
- **data**: render any custom data from `Message.opts`. Useful in combination with the opts passed to `vim.notify`

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
    { "{kind}", before = { ".", hl_group = "NoiceFormatKind" } },
    " ",
    "{title} ",
    "{cmdline} ",
    "{message}",
  },
  telescope = ..., -- formatter used to display telescope results
  telescope_preview = ..., -- formatter used to preview telescope results
  lsp_progress = ..., -- formatter used by lsp progress
  lsp_progress_done = ..., -- formatter used by lsp progress
}
```

Text before/after the formatter or in the before/after options, will only be rendered if the formatter itself rendered something.

The `format` view option, can be either a `string` (one of the built-in formats), or a table with a custom format definition.

To align text, you can use the `align` option for a view. Can be `center`, `left` or `right`.

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
        require("noice").api.status.message.get_hl,
        cond = require("noice").api.status.message.has,
      },
      {
        require("noice").api.status.command.get,
        cond = require("noice").api.status.command.has,
        color = { fg = "#ff9e64" },
      },
      {
        require("noice").api.status.mode.get,
        cond = require("noice").api.status.mode.has,
        color = { fg = "#ff9e64" },
      },
      {
        require("noice").api.status.search.get,
        cond = require("noice").api.status.search.has,
        color = { fg = "#ff9e64" },
      },
    },
  },
})
```

</details>

## 🔭 Telescope

In order to use **Noice** in **Telescope**, you can either do `:Noice telescope`,
or register the extension and use `:Telescope noice`.
The results panel is formatted using `config.format.formatters.telescope`. The preview is formatted with `config.format.formatters.telescope_preview`

```lua
require("telescope").load_extension("noice")
```

## 🚀 Usage

- `:Noice` or `:Noice history` shows the message history
- `:Noice last` shows the last message in a popup
- `:Noice dismiss` dismiss all visible messages
- `:Noice errors` shows the error messages in a split. Last errors on top
- `:Noice disable` disables **Noice**
- `:Noice enable` enables **Noice**
- `:Noice stats` shows debugging stats
- `:Noice telescope` opens message history in Telescope

Alternatively, all commands also exist as a full name like `:NoiceLast`, `:NoiceDisable`.

You can also use `Lua` equivalents.

```lua
vim.keymap.set("n", "<leader>nl", function()
  require("noice").cmd("last")
end)

vim.keymap.set("n", "<leader>nh", function()
  require("noice").cmd("history")
end)
```

> You can add custom commands with `config.commands`

### ↪️ Command Redirection

Sometimes it's useful to redirect the messages generated by a command or function
to a different view. That can be easily achieved with command redirection.

The redirect API can taken an optional `routes` parameter, which defaults to `{config.redirect}`.

```lua
-- redirect ":hi"
require("noice").redirect("hi")

-- redirect some function
require("noice").redirect(function()
  print("test")
end)
```

Adding the following keymap, will redirect the active cmdline when pressing `<S-Enter>`.
The cmdline stays open, so you can change the command and execute it again.
When exiting the cmdline, the popup window will be focused.

```lua
vim.keymap.set("c", "<S-Enter>", function()
  require("noice").redirect(vim.fn.getcmdline())
end, { desc = "Redirect Cmdline" })
```

### Lsp Hover Doc Scrolling

```lua
vim.keymap.set({ "n", "i", "s" }, "<c-f>", function()
  if not require("noice.lsp").scroll(4) then
    return "<c-f>"
  end
end, { silent = true, expr = true })

vim.keymap.set({ "n", "i", "s" }, "<c-b>", function()
  if not require("noice.lsp").scroll(-4) then
    return "<c-b>"
  end
end, { silent = true, expr = true })
```

## 🌈 Highlight Groups

<details>
<summary>Click to see all highlight groups</summary>

<!-- hl_start -->

| Highlight Group                        | Default Group                    | Description                                        |
| -------------------------------------- | -------------------------------- | -------------------------------------------------- |
| **NoiceCmdline**                       | _MsgArea_                        | Normal for the classic cmdline area at the bottom" |
| **NoiceCmdlineIcon**                   | _DiagnosticSignInfo_             | Cmdline icon                                       |
| **NoiceCmdlineIconCalculator**         | _NoiceCmdlineIcon_               |                                                    |
| **NoiceCmdlineIconCmdline**            | _NoiceCmdlineIcon_               |                                                    |
| **NoiceCmdlineIconFilter**             | _NoiceCmdlineIcon_               |                                                    |
| **NoiceCmdlineIconHelp**               | _NoiceCmdlineIcon_               |                                                    |
| **NoiceCmdlineIconIncRename**          | _NoiceCmdlineIcon_               |                                                    |
| **NoiceCmdlineIconInput**              | _NoiceCmdlineIcon_               |                                                    |
| **NoiceCmdlineIconLua**                | _NoiceCmdlineIcon_               |                                                    |
| **NoiceCmdlineIconSearch**             | _DiagnosticSignWarn_             | Cmdline search icon (`/` and `?`)                  |
| **NoiceCmdlinePopup**                  | _Normal_                         | Normal for the cmdline popup                       |
| **NoiceCmdlinePopupBorder**            | _DiagnosticSignInfo_             | Cmdline popup border                               |
| **NoiceCmdlinePopupBorderCalculator**  | _NoiceCmdlinePopupBorder_        |                                                    |
| **NoiceCmdlinePopupBorderCmdline**     | _NoiceCmdlinePopupBorder_        |                                                    |
| **NoiceCmdlinePopupBorderFilter**      | _NoiceCmdlinePopupBorder_        |                                                    |
| **NoiceCmdlinePopupBorderHelp**        | _NoiceCmdlinePopupBorder_        |                                                    |
| **NoiceCmdlinePopupBorderIncRename**   | _NoiceCmdlinePopupBorder_        |                                                    |
| **NoiceCmdlinePopupBorderInput**       | _NoiceCmdlinePopupBorder_        |                                                    |
| **NoiceCmdlinePopupBorderLua**         | _NoiceCmdlinePopupBorder_        |                                                    |
| **NoiceCmdlinePopupBorderSearch**      | _DiagnosticSignWarn_             | Cmdline popup border for search                    |
| **NoiceCmdlinePopupTitle**             | _DiagnosticSignInfo_             | Cmdline popup border                               |
| **NoiceCmdlinePrompt**                 | _Title_                          | prompt for input()                                 |
| **NoiceCompletionItemKindClass**       | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindColor**       | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindConstant**    | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindConstructor** | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindDefault**     | _Special_                        |                                                    |
| **NoiceCompletionItemKindEnum**        | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindEnumMember**  | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindField**       | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindFile**        | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindFolder**      | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindFunction**    | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindInterface**   | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindKeyword**     | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindMethod**      | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindModule**      | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindProperty**    | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindSnippet**     | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindStruct**      | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindText**        | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindUnit**        | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindValue**       | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemKindVariable**    | _NoiceCompletionItemKindDefault_ |                                                    |
| **NoiceCompletionItemMenu**            | _none_                           | Normal for the popupmenu                           |
| **NoiceCompletionItemWord**            | _none_                           | Normal for the popupmenu                           |
| **NoiceConfirm**                       | _Normal_                         | Normal for the confirm view                        |
| **NoiceConfirmBorder**                 | _DiagnosticSignInfo_             | Border for the confirm view                        |
| **NoiceCursor**                        | _Cursor_                         | Fake Cursor                                        |
| **NoiceFormatConfirm**                 | _CursorLine_                     |                                                    |
| **NoiceFormatConfirmDefault**          | _Visual_                         |                                                    |
| **NoiceFormatDate**                    | _Special_                        |                                                    |
| **NoiceFormatEvent**                   | _NonText_                        |                                                    |
| **NoiceFormatKind**                    | _NonText_                        |                                                    |
| **NoiceFormatLevelDebug**              | _NonText_                        |                                                    |
| **NoiceFormatLevelError**              | _DiagnosticVirtualTextError_     |                                                    |
| **NoiceFormatLevelInfo**               | _DiagnosticVirtualTextInfo_      |                                                    |
| **NoiceFormatLevelOff**                | _NonText_                        |                                                    |
| **NoiceFormatLevelTrace**              | _NonText_                        |                                                    |
| **NoiceFormatLevelWarn**               | _DiagnosticVirtualTextWarn_      |                                                    |
| **NoiceFormatProgressDone**            | _Search_                         | Progress bar done                                  |
| **NoiceFormatProgressTodo**            | _CursorLine_                     | progress bar todo                                  |
| **NoiceFormatTitle**                   | _Title_                          |                                                    |
| **NoiceLspProgressClient**             | _Title_                          | Lsp progress client name                           |
| **NoiceLspProgressSpinner**            | _Constant_                       | Lsp progress spinner                               |
| **NoiceLspProgressTitle**              | _NonText_                        | Lsp progress title                                 |
| **NoiceMini**                          | _MsgArea_                        | Normal for mini view                               |
| **NoicePopup**                         | _NormalFloat_                    | Normal for popup views                             |
| **NoicePopupBorder**                   | _FloatBorder_                    | Border for popup views                             |
| **NoicePopupmenu**                     | _Pmenu_                          | Normal for the popupmenu                           |
| **NoicePopupmenuBorder**               | _FloatBorder_                    | Popupmenu border                                   |
| **NoicePopupmenuMatch**                | _Special_                        | Part of the item that matches the input            |
| **NoicePopupmenuSelected**             | _PmenuSel_                       | Selected item in the popupmenu                     |
| **NoiceScrollbar**                     | _PmenuSbar_                      | Normal for scrollbar                               |
| **NoiceScrollbarThumb**                | _PmenuThumb_                     | Scrollbar thumb                                    |
| **NoiceSplit**                         | _NormalFloat_                    | Normal for split views                             |
| **NoiceSplitBorder**                   | _FloatBorder_                    | Border for split views                             |
| **NoiceVirtualText**                   | _DiagnosticVirtualTextInfo_      | Default hl group for virtualtext views             |

<!-- hl_end -->

</details>
