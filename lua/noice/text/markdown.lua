local require = require("noice.util.lazy")

local NoiceText = require("noice.text")
local Config = require("noice.config")

local M = {}

---@param message NoiceMessage
---@param text string
function M.format(message, text)
  text = text:gsub("\n\n\n", "\n\n")
  text = text:gsub("\n%s*\n```", "\n```")
  text = text:gsub("```\n%s*\n", "```\n")

  local lines = vim.split(vim.trim(text), "\n")

  for l, line in ipairs(lines) do
    if l ~= 1 then
      message:newline()
    end
    -- Make the horizontal ruler extend the whole window width
    if line:find("^[%*%-_][%*%-_][%*%-_]+$") then
      M.horizontal_line(message)
    else
      message:append(line)
      for pattern, hl_group in pairs(Config.options.markdown.highlights) do
        local from, to, match = line:find(pattern)
        if match then
          from, to = line:find(match, from)
        end
        if from then
          message:append(NoiceText("", {
            hl_group = hl_group,
            col = from - 1,
            length = to - from + 1,
          }))
        end
      end
    end
  end
end

return M
