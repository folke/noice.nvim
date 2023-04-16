local require = require("noice.util.lazy")

local View = require("noice.view")
local Manager = require("noice.message.manager")
local Config = require("noice.config")
local Util = require("noice.util")
local Message = require("noice.message")
local Router = require("noice.message.router")

---@class NoiceCommand: NoiceRouteConfig
---@field filter_opts NoiceMessageOpts

local M = {}

---@type table<string, fun()>
M.commands = {}

---@param command NoiceCommand
function M.command(command)
  return function()
    local view = View.get_view(command.view, command.opts)
    view:set(Manager.get(
      command.filter,
      vim.tbl_deep_extend("force", {
        history = true,
        sort = true,
      }, command.filter_opts or {})
    ))
    view:display()
  end
end

function M.cmd(cmd)
  if M.commands[cmd] then
    M.commands[cmd]()
  else
    M.commands.history()
  end
end

function M.setup()
  M.commands = {
    debug = function()
      Config.options.debug = not Config.options.debug
    end,
    dismiss = function()
      Router.dismiss()
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
    viewstats = function()
      local message = Message("noice", "debug")
      message:set(vim.inspect(require("noice.message.router").view_stats()))
      Manager.add(message)
    end,
  }

  for name, command in pairs(Config.options.commands) do
    M.commands[name] = M.command(command)
  end

  vim.api.nvim_create_user_command("Noice", function(args)
    local cmd = vim.trim(args.args or "")
    M.cmd(cmd)
  end, {
    nargs = "?",
    desc = "Noice",
    complete = function(_, line)
      if line:match("^%s*Noice %w+ ") then
        return {}
      end
      local prefix = line:match("^%s*Noice (%w*)") or ""
      return vim.tbl_filter(function(key)
        return key:find(prefix) == 1
      end, vim.tbl_keys(M.commands))
    end,
  })

  for name in pairs(M.commands) do
    local cmd = "Noice" .. name:sub(1, 1):upper() .. name:sub(2)
    vim.api.nvim_create_user_command(cmd, function()
      M.cmd(name)
    end, { desc = "Noice " .. name })
  end
end

return M
