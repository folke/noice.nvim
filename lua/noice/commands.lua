local require = require("noice.util.lazy")

local View = require("noice.view")
local Manager = require("noice.manager")
local Config = require("noice.config")
local Stats = require("noice.stats")

local M = {}

---@type NoiceView?
M._history_view = nil

function M.setup()
  local commands = {
    stats = function()
      Manager.add(Stats.message())
    end,
    history = function()
      if not M._history_view then
        M._history_view = View.get_view(Config.options.history.view, Config.options.history.opts)
      end
      M._history_view:display(Manager.get(Config.options.history.filter, {
        history = true,
        sort = true,
      }))
      M._history_view:show()
    end,
  }

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
      if line:match("^Noice %w+ ") then
        return {}
      end
      local prefix = line:match("^Noice (%w*)")
      return vim.tbl_filter(function(key)
        return key:find(prefix) == 1
      end, vim.tbl_keys(commands))
    end,
  })
end

return M
