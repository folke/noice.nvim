local M = {}

function M.setup()
  require("noice.config").setup()
  require("noice.hacks").setup()
  require("noice.router").setup()
  require("noice.ui").setup()
end

return M
