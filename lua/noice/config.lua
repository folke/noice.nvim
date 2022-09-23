local M = {}

M.ns = vim.api.nvim_create_namespace("messages_highlights")

---@class NoiceConfig
M.defaults = {
  debug = true,
  throttle = 1000 / 30,
  cmdline = {
    enabled = true,
    syntax_highlighting = true, -- apply vim (and injected lua) syntax highlighting to the cmdline
    menu = "popup", -- @type "popup" | "wild"
  },
}

--- @type NoiceConfig
M.options = {}

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
end

return M
