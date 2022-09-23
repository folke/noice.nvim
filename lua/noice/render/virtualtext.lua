local Config = require("noice.config")

---@param view NoiceView
return function(view)
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  line = line - 1
  -- dump({ line = line, col = col })
  vim.api.nvim_buf_clear_namespace(0, Config.ns, 0, -1)
  vim.api.nvim_buf_set_extmark(0, Config.ns, line, col, {
    virt_text = { { view.messages[1]:content(), "IncSearch" } },
  })
end
