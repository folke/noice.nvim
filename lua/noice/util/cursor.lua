local require = require("noice.util.lazy")

local Config = require("noice.config")
local Cmdline = require("noice.ui.cmdline")

local M = {}

---@param bufnr buffer
---@param row number (1-indexing)
---@param col number (0-indexing)
function M.render_cursor(bufnr, row, col)
  -- disable for now. Doesn't work will due to triggering of autocmds
  -- local win = vim.fn.bufwinid(bufnr)
  -- if win ~= -1 then
  --   vim.api.nvim_win_set_cursor(win, { row, col })
  --   vim.api.nvim_set_current_win(win)
  --   return
  -- end
  M.render_fake_cursor(bufnr, row, col)
end

---@param bufnr buffer
---@param row number (1-indexing)
---@param col number (0-indexing)
function M.render_fake_cursor(bufnr, row, col)
  ---@type string
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, true)[1]
  local line_width = vim.fn.strwidth(line)
  if col >= line_width then
    -- end of line, so use a virtual text
    vim.api.nvim_buf_set_extmark(bufnr, Config.ns, row - 1, 0, {
      virt_text = { { " ", "Cursor" } },
      virt_text_win_col = col,
    })
  else
    -- use a regular extmark
    vim.api.nvim_buf_set_extmark(bufnr, Config.ns, row - 1, col, {
      end_col = col + 1,
      hl_group = "Cursor",
    })
  end
end

---@return {win: window, buf: buffer, win_cursor:number[], screen_cursor:number[], offset:number}?
function M.get_cmdline_cursor()
  local cursor = Cmdline.message.cursor
  if cursor and cursor.buf then
    local win = vim.fn.bufwinid(cursor.buf)
    local offset = cursor.offset
    if win ~= -1 then
      local win_cursor = { cursor.buf_line, vim.fn.getcmdpos() - 1 }
      local pos = vim.fn.screenpos(win, win_cursor[1], win_cursor[2] + offset + 1)
      return {
        win = win,
        buf = cursor.buf,
        offset = offset,
        win_cursor = win_cursor,
        screen_cursor = { pos.row, pos.col - 1 },
      }
    end
  end
end

return M
