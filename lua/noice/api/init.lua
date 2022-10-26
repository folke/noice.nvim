local require = require("noice.util.lazy")

local Cmdline = require("noice.ui.cmdline")
local Status = require("noice.api.status")

local M = {}

M.status = Status

---@deprecated
M.statusline = Status

---@return CmdlinePosition?
function M.get_cmdline_position()
  return Cmdline.position and vim.deepcopy(Cmdline.position)
end

return M
