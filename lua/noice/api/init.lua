local require = require("noice.util.lazy")

local Cmdline = require("noice.ui.cmdline")
local Statusline = require("noice.api.statusline")

local M = {}

M.statusline = Statusline

---@return CmdlinePosition?
function M.get_cmdline_position()
  return Cmdline.position and vim.deepcopy(Cmdline.position)
end

return M
