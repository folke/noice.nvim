local M = {}

function M.setup()
  if vim.fn.has("nvim-0.8.0") ~= 1 then
    require("noice.util").error("Noice needs Neovim >= 0.8.0")
    return
  end
  if not pcall(require, "notify") then
    require("noice.util").error("Noice needs nvim-notify to work properly")
    return
  end
  require("noice.config").setup()
  require("noice.hacks").setup()
  require("noice.commands").setup()
  require("noice.router").setup()
  require("noice.ui").setup()
end

return M
