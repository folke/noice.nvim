local M = {}

---@param opts? NoiceConfig
function M.setup(opts)
  if vim.fn.has("nvim-0.8.0") ~= 1 then
    require("noice.util").error("Noice needs Neovim >= 0.8.0")
    -- require("noice.util").error("Noice needs Neovim >= 0.9.0 (nightly)")
    return
  end
  if not pcall(require, "notify") then
    require("noice.util").error("Noice needs nvim-notify to work properly")
    return
  end
  require("noice.config").setup(opts)
  require("noice.hacks").setup()
  require("noice.commands").setup()
  require("noice.router").setup()
  require("noice.ui").setup()
end

function M.disable()
  require("noice.router").stop()
  require("noice.ui").detach()
end

function M.enable()
  require("noice.ui").attach()
  require("noice.router").start()
end

return M
