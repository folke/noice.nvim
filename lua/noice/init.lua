local M = {}

function M.setup()
	require("noice.config").setup()
	require("noice.handlers").setup()
	require("noice.ui").setup()
end

return M
