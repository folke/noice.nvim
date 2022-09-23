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
      if message then
        local ret = ""
        for _, line in ipairs(message._lines) do
          for _, text in ipairs(line._texts) do
            ret = ret .. "%#" .. text.extmark.hl_group .. "#" .. text:content()
          end
        end
        return ret
      end
    end,
  }
end

M.ruler = NoiceStatus()
M.command = NoiceStatus()
M.mode = NoiceStatus()
M.search = NoiceStatus()

return M
