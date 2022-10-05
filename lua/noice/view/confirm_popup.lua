---@diagnostic disable: undefined-field, undefined-doc-class
local require = require("noice.util.lazy")
local NoiceView = require("noice.view.nui")
local NuiLine = require("nui.line")

---@class NuiView: NoiceView
---@diagnostic disable-next-line: undefined-field
local NuiConfirmView = NoiceView:extend("NuiConfirmView")

local function center_text(str, width)
  if #str >= width then return str end
  local padding = math.floor((width - #str) / 2)
  return string.rep(' ', padding) .. str .. string.rep(' ', padding)
end

function NuiConfirmView:show()
  if #self._messages ~= 1 then
    NoiceView.show(self)
    return
  end
  local size = self:get_layout().size
  local msg = self._messages[1]
  local button_line = msg._lines[#msg._lines]
  local text_button = button_line:content()
  local buttons = vim.split(text_button, ",", {})
  local default = 0
  local max_length = 0
  -- change text to button
  for i, b in ipairs(buttons) do
    if b:find("%[") then default = i end
    b = vim.trim(string.gsub(b, ":", ""))
    buttons[i] = b
    if #b > max_length then
      max_length = #b
    end
  end
  button_line._texts = {}
  local padding = math.floor((size.width - #text_button) / 2)
  button_line:append(string.rep(' ', padding - #buttons))
  for i, b in ipairs(buttons) do
    button_line:append(center_text(b, max_length + 2),
      i == default and self._view_opts.ui_highlights.default_button
      or self._view_opts.ui_highlights.button
    )
    button_line:append(' ')
  end

  local max_width = button_line:width() > size.width and button_line:width() or size.width
  for i, line in ipairs(msg._lines) do
    if i ~= #msg._lines then
      local text = line:content()
      line._texts = {}
      line:append(center_text(text, max_width))
    end
  end

  table.remove(msg._lines, 1)
  table.insert(msg._lines, #msg._lines, NuiLine())

  NoiceView.check_options(self)
  NoiceView.show(self)
end

return function(opts)
  opts.type = "popup"
  return NuiConfirmView(opts)

end
