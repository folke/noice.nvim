local M = {}

M.ns = vim.api.nvim_create_namespace("messages_highlights")

---@class Config
M.defaults = {
	debug = true,
	throttle = 100,
}

--- @type Config
M.options = {}

function M.setup(options)
	M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
end

return M
