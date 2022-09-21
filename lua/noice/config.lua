local M = {}

M.ns = vim.api.nvim_create_namespace("messages_highlights")

---@class Config
M.defaults = {
	debug = true,
	throttle = 1000 / 30,
	cmdline = {
		enabled = true,
		menu = "popup", -- @type "popup" | "wild"
	},
}

--- @type Config
M.options = {}

function M.setup(options)
	M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
end

return M
