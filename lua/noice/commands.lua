local require = require("noice.util.lazy")

local View = require("noice.view")
local Manager = require("noice.message.manager")
local Config = require("noice.config")
local Util = require("noice.util")
local Message = require("noice.message")

---@class NoiceCommand: NoiceRouteConfig
---@field filter_opts NoiceMessageOpts

local M = {}

---@param command NoiceCommand
function M.command(command)
  return function()
    local view = View.get_view(command.view, command.opts)
    view:display(Manager.get(
      command.filter,
      vim.tbl_deep_extend("force", {
        history = true,
        sort = true,
      }, command.filter_opts or {})
    ))
    view:show()
  end
end

function M.setup()
  local commands = {
    debug = function()
      Config.options.debug = not Config.options.debug
    end,
    log = function()
      vim.cmd.edit(Config.options.log)
    end,
    enable = function()
      require("noice").enable()
    end,
    disable = function()
      require("noice").disable()
    end,
    telescope = function()
      require("telescope").extensions.noice.noice({})
    end,
    stats = function()
      Manager.add(Util.stats.message())
    end,
    routes = function()
      local message = Message("noice", "debug")
      message:set(vim.inspect(Config.options.routes))
      Manager.add(message)
    end,
    config = function()
      local message = Message("noice", "debug")
      message:set(vim.inspect(Config.options))
      Manager.add(message)
    end,
  }

  for name, command in pairs(Config.options.commands) do
    commands[name] = M.command(command)
  end

  vim.api.nvim_create_user_command("Noice", function(args)
    local cmd = vim.trim(args.args or "")
    if commands[cmd] then
      commands[cmd]()
    else
      commands.history()
    end
  end, {
    nargs = "?",
    desc = "Noice",
    complete = function(f, line, ...)
      if line:match("^%s*Noice %w+ ") then
        return {}
      end
      local prefix = line:match("^%s*Noice (%w*)")
      return vim.tbl_filter(function(key)
        return key:find(prefix) == 1
      end, vim.tbl_keys(commands))
    end,
  })
end

return M
