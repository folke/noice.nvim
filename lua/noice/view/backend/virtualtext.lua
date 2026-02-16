local require = require("noice.util.lazy")

local Config = require("noice.config")
local View = require("noice.view")

---@class VirtualText: NoiceView
---@field extmark? number
---@field buf? number
---@diagnostic disable-next-line: undefined-field
local VirtualText = View:extend("VirtualTextView")

function VirtualText:show()
  self:hide()
  self.buf = vim.api.nvim_get_current_buf()

  ---@type number, number
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  line = line - 1

  if self._messages[1] then
    local text = vim.trim(self._messages[1]:content())
    local hl = self._opts.hl_group or "DiagnosticVirtualTextInfo"
    local pos = self._opts.virt_text_pos or "right_inline"

    local extmark_opts = { hl_mode = "combine" }

    -- Compute code-line boundaries (first and last non-blank columns)
    local line_text = vim.api.nvim_buf_get_lines(self.buf, line, line + 1, false)[1] or ""
    local indent = vim.fn.strdisplaywidth(line_text:match("^%s*") or "")
    local content_end = vim.fn.strdisplaywidth((line_text:match("^(.-)%s*$") or ""))

    if pos == "right_inline" then
      extmark_opts.virt_text = { { text, hl } }
      extmark_opts.virt_text_pos = "eol"
    elseif pos == "left_upper" or pos == "left_lower" then
      local pad = string.rep(" ", indent)
      extmark_opts.virt_lines = { { { pad, "" }, { text, hl } } }
      extmark_opts.virt_lines_above = (pos == "left_upper")
    elseif pos == "right_upper" or pos == "right_lower" then
      local text_width = vim.fn.strdisplaywidth(text)
      local pad = math.max(content_end - text_width, 0)
      extmark_opts.virt_lines = { { { string.rep(" ", pad), "" }, { text, hl } } }
      extmark_opts.virt_lines_above = (pos == "right_upper")
    else
      extmark_opts.virt_text = { { text, hl } }
      extmark_opts.virt_text_pos = "eol"
    end

    self.extmark = vim.api.nvim_buf_set_extmark(self.buf, Config.ns, line, col, extmark_opts)
  end
end

function VirtualText:hide()
  if self.extmark and vim.api.nvim_buf_is_valid(self.buf) then
    vim.api.nvim_buf_del_extmark(self.buf, Config.ns, self.extmark)
  end
end

return VirtualText
