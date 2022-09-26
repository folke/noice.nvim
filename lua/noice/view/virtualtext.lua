local Config = require("noice.config")
local View = require("noice.view")

---@class VirtualText: NoiceView
---@field extmark? number
---@diagnostic disable-next-line: undefined-field
local VirtualText = View:extend("VirtualTextView")

function VirtualText:show()
  self:hide()

  ---@type number, number
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  line = line - 1

  if self._messages[1] then
    self.extmark = vim.api.nvim_buf_set_extmark(0, Config.ns, line, col, {
      virt_text_pos = "eol",
      virt_text = { { vim.trim(self._messages[1]:content()), self._opts.hl_group or "DiagnosticVirtualTextInfo" } },
    })
  end
end

function VirtualText:hide()
  if self.extmark then
    vim.api.nvim_buf_del_extmark(0, Config.ns, self.extmark)
  end
end

return VirtualText
