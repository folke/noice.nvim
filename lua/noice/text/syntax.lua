local M = {}

--- Highlights a region of the buffer with a given language
---@param buf buffer buffer to highlight. Defaults to the current buffer if 0
---@param ns number namespace for the highlights
---@param range {[1]:number, [2]:number, [3]: number, [4]: number} (table) Region to highlight {start_row, start_col, end_row, end_col}
---@param lang string treesitter language
function M.highlight(buf, ns, range, lang)
  vim.api.nvim_buf_call(buf, function()
    local group = "@" .. lang:upper()

    -- HACK: reset current_syntax, since some syntax files like markdown won't load if it is already set
    pcall(vim.api.nvim_buf_del_var, buf, "current_syntax")
    if not pcall(vim.cmd, string.format("syntax include %s syntax/%s.vim", group, lang)) then
      return
    end
    vim.cmd(
      string.format(
        "syntax region %s start=+\\%%%dl+ end=+\\%%%dl+ contains=%s keepend",
        lang .. range[1],
        range[1] + 1,
        range[3] + 1,
        group
      )
    )
  end)
end

return M
