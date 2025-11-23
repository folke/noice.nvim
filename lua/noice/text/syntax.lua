local M = {}

local function fix(str)
  return str:gsub("[^%w_%.%-]+", "_")
end

--- Highlights a region of the buffer with a given language
---@param buf buffer buffer to highlight. Defaults to the current buffer if 0
---@param ns number namespace for the highlights
---@param range {[1]:number, [2]:number, [3]: number, [4]: number} (table) Region to highlight {start_row, start_col, end_row, end_col}
---@param lang string treesitter language
function M.highlight(buf, ns, range, lang)
  vim.api.nvim_buf_call(buf, function()
    lang = fix(lang)
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
    
    if lang == "vim" then
      local ok = pcall(vim.cmd, string.format([[
        syntax match NoiceCmdlineCommand /\v^\s*\w+/ display
        highlight default link NoiceCmdlineCommand Statement
      ]]))
      
      if ok then
        local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
        if line then
          local cmd_end = line:find("%s") or #line + 1
          if cmd_end > 1 then
            vim.api.nvim_buf_add_highlight(buf, ns, "NoiceCmdlineCommand", 0, 0, cmd_end - 1)
          end
        end
      end
    end
  end)
end

return M
