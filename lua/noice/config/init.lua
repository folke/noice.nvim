local require = require("noice.util.lazy")

local Routes = require("noice.config.routes")

local M = {}

M.ns = vim.api.nvim_create_namespace("noice")

function M.defaults()
  ---@class NoiceConfig
  local defaults = {
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
        help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
        calculator = { pattern = "^=", icon = "", lang = "vimnormal" },
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
      cmdline_output_to_split = false, -- send the output of a command you executed in the cmdline to a split
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
    debug = false,
    log = vim.fn.stdpath("state") .. "/noice.log",
    log_max_size = 1024 * 1024 * 2, -- 10MB
  }
  return defaults
end

--- @type NoiceConfig
M.options = {}

M._running = false
function M.is_running()
  return M._running
end

function M.setup(options)
  options = options or {}

  M.fix_legacy(options)

  if options.popupmenu and options.popupmenu.kind_icons == true then
    options.popupmenu.kind_icons = nil
  end

  M.options = vim.tbl_deep_extend("force", {}, M.defaults(), {
    views = require("noice.config.views").defaults,
    status = require("noice.config.status").defaults,
    format = require("noice.config.format").defaults,
    popupmenu = {
      kind_icons = require("noice.config.icons").kinds,
    },
  })

  M.truncate_log()

  require("noice.config.preset").setup(options)

  local routes = M.options.routes
  M.options = vim.tbl_deep_extend("force", M.options, options)
  vim.list_extend(M.options.routes, routes)

  if M.options.popupmenu.kind_icons == false then
    M.options.popupmenu.kind_icons = {}
  end

  require("noice.config.cmdline").setup()

  M.options.routes = Routes.get(M.options.routes)

  require("noice.config.highlights").setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      require("noice.config.highlights").setup()
    end,
  })

  require("noice.lsp").setup()
  M._running = true
end

function M.truncate_log()
  local stat = vim.loop.fs_stat(M.options.log)
  if stat and stat.size > M.options.log_max_size then
    io.open(M.options.log, "w+"):close()
  end
end

---@param opts NoiceConfig
function M.fix_legacy(opts)
  if opts.lsp and opts.lsp.signature and type(opts.lsp.signature.auto_open) == "boolean" then
    opts.lsp.signature.auto_open = {
      enabled = opts.lsp.signature.auto_open,
    }
  end
  if opts.lsp_progress then
    opts.lsp = opts.lsp or {}
    opts.lsp.progress = opts.lsp_progress
    opts.lsp_progress = nil
  end
  if opts.history then
    opts.commands = opts.commands or {}
    opts.commands.history = opts.history
    opts.history = nil
  end
end

return M
