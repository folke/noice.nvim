local M = {}

local data = {}

---@see https://github.com/neovim/neovim/issues/17810
function M.fix_incsearch(enable)
  if enable then
    if vim.wo.conceallevel ~= 0 and data.conceallevel == nil then
      data.conceallevel = vim.wo.conceallevel
      vim.wo.conceallevel = 0
    end
  elseif data.conceallevel ~= nil then
    vim.wo.conceallevel = data.conceallevel
    data.conceallevel = nil
  end
end

return M
