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

function M.keys(buf)
  if vim.b[buf].markdown_keys then
    return
  end

  local function map(lhs)
    vim.keymap.set("n", lhs, function()
      local line = vim.api.nvim_get_current_line()
      local pos = vim.api.nvim_win_get_cursor(0)
      local col = pos[2] + 1

      for pattern, handler in pairs(require("noice.config").options.markdown.hover) do
        local from = 1
        local to, url
        while from do
          from, to, url = line:find(pattern, from)
          if from and col >= from and col <= to then
            return handler(url)
          end
        end
      end
      vim.api.nvim_feedkeys(lhs, "n", false)
    end, { buffer = buf, silent = true })
  end

  map("gx")
  map("K")

  vim.b[buf].markdown_keys = true
end

---@param message NoiceMessage
function M.horizontal_line(message)
  message:append(NoiceText("", {
    virt_text_win_col = 0,
    virt_text = { { string.rep("─", vim.go.columns), "@punctuation.special.markdown" } },
    priority = 100,
  }))
end

return M
