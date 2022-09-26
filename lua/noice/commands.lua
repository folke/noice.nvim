local View = require("noice.view")
local Manager = require("noice.manager")
local Config = require("noice.config")

local M = {}

---@type NoiceView?
M._history_view = nil

function M.setup()
  vim.api.nvim_create_user_command("Noice", function()
    if not M._history_view then
      M._history_view = View.get_view(Config.options.history.view, Config.options.history.opts)
    end
    M._history_view:display(Manager.get(Config.options.history.filter, {
      history = true,
      sort = true,
    }))
    M._history_view:show()
  end, {
    desc = "Open Noice Message History",
  })
end

return M
