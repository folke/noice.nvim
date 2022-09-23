local M = {}

local function NoiceStatus()
  ---@type NoiceMessage?
  local message
  return {
    clear = function()
      message = nil
    end,
    has = function()
      return message ~= nil
    end,
    set = function(m)
      message = m
    end,
    get = function()
      if message then
        return vim.trim(message:content())
      end
    end,
    get_hl = function()
      if message and message._lines[1] then
        local ret = ""
        local line = message._lines[#message._lines]
        for _, text in ipairs(line._texts) do
          ret = ret .. "%#" .. text.extmark.hl_group .. "#" .. text:content()
        end
        return ret
      end
    end,
  }
end

M.ruler = NoiceStatus()
M.message = NoiceStatus()
M.command = NoiceStatus()
M.mode = NoiceStatus()
M.search = NoiceStatus()

return M
