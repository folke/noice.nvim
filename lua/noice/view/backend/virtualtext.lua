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
    self.extmark = vim.api.nvim_buf_set_extmark(self.buf, Config.ns, line, col, {
      virt_text_pos = "eol",
      virt_text = { { vim.trim(self._messages[1]:content()), self._opts.hl_group or "DiagnosticVirtualTextInfo" } },
      hl_mode = "combine",
    })
  end
end

function VirtualText:hide()
  if self.extmark and vim.api.nvim_buf_is_valid(self.buf) then
    vim.api.nvim_buf_del_extmark(self.buf, Config.ns, self.extmark)
  end
end

return VirtualText
