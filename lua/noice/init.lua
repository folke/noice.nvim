local M = {}

function M.setup()
	require("noice.config").setup()
	require("noice.view").setup()
	require("noice.ui").setup()
end

return M
