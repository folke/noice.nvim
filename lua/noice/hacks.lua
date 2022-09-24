local M = {}

function M.setup()
  M.fix_incsearch()
end

---@see https://github.com/neovim/neovim/issues/17810
function M.fix_incsearch()
  local group = vim.api.nvim_create_augroup("noice.incsearch", { clear = true })

  ---@type integer|string|nil
  local conceallevel

  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = group,
    callback = function(event)
      if event.match == "/" or event.match == "?" then
        conceallevel = vim.wo.conceallevel
        vim.wo.conceallevel = 0
      end
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = function(event)
      if conceallevel and (event.match == "/" or event.match == "?") then
        vim.wo.conceallevel = conceallevel
        conceallevel = nil
      end
    end,
  })
end

return M
