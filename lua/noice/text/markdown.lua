local require = require("noice.util.lazy")

local NoiceText = require("noice.text")
local Config = require("noice.config")

local M = {}

function M.is_rule(line)
  return line and line:find("^[%*%-_][%*%-_][%*%-_]+$")
end

function M.is_code_block(line)
  return line and line:find("^%s*```")
end

function M.is_empty(line)
  return line and line:find("^%s*$")
end

function M.trim(lines)
  local ret = {}
  local l = 1
  while l <= #lines do
    local line = lines[l]
    if M.is_empty(line) then
      while M.is_empty(lines[l + 1]) do
        l = l + 1
      end
      if not (M.is_code_block(lines[l + 1]) or M.is_rule(lines[l + 1])) then
        table.insert(ret, line)
      end
    elseif M.is_code_block(line) or M.is_rule(line) then
      table.insert(ret, line)
      while M.is_empty(lines[l + 1]) do
        l = l + 1
      end
    else
      table.insert(ret, line)
    end
    l = l + 1
  end
  return ret
end

---@param message NoiceMessage
---@param text string
function M.format(message, text)
  local lines = vim.split(vim.trim(text), "\n")
  lines = M.trim(lines)

  for l, line in ipairs(lines) do
    local prev = lines[l - 1]
    local next = lines[l + 1]

    if M.is_rule(line) and M.is_code_block(prev) then
      -- add the rule on top of the end of the code block
      M.horizontal_line(message)
    elseif
      M.is_rule(line) and M.is_code_block(next)
      -- will be taken care of at the next iteration
    then
    else
      if l ~= 1 then
        message:newline()
      end
      if M.is_code_block(line) and M.is_rule(prev) then
        M.horizontal_line(message)
      end
      -- Make the horizontal ruler extend the whole window width
      if M.is_rule(line) then
        M.horizontal_line(message)
      else
        message:append(line)
        for pattern, hl_group in pairs(Config.options.markdown.highlights) do
          local from = 1
          while from do
            local to, match
            from, to, match = line:find(pattern, from)
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
            from = to and to + 1 or nil
          end
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

      for pattern, handler in pairs(Config.options.markdown.hover) do
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
