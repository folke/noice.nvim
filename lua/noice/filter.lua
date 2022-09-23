local Util = require("noice.util")

local M = {}

---@alias NoiceFilterFun fun(message: NoiceMessage, ...): boolean

---@class NoiceFilter
---@field event? string
---@field kind? string
---@field message? NoiceMessage
---@field keep? boolean

-----@type table<string, NoiceFilterFun>
M.filters = {
  event = function(message, event)
    ---@cast message NoiceMessage
    return event == message.event
  end,
  kind = function(message, kind)
    ---@cast message NoiceMessage
    return kind == message.kind
  end,
  message = function(message, other)
    ---@cast message NoiceMessage
    return other == message
  end,
  keep = function(message, keep)
    ---@cast message NoiceMessage
    return message.keep == keep
  end,
}

---@param message NoiceMessage
---@param filter NoiceFilter
function M.is(message, filter)
  for k, v in pairs(filter) do
    if M.filters[k] then
      if not M.filters[k](message, v) then
        return false
      end
    else
      Util.error("Unknown filter key " .. k .. " for " .. vim.input(filter))
      return false
    end
  end
  return true
end

---@param messages NoiceMessage[]
---@param filter NoiceFilter
---@param invert? boolean
---@return NoiceMessage[]
function M.filter(messages, filter, invert)
  return vim.tbl_filter(function(message)
    ---@cast message NoiceMessage
    local is = M.is(message, filter)
    if invert then
      is = not is
    end
    return is
  end, messages)
end

---@param messages NoiceMessage[]
---@param filter NoiceFilter
---@param invert? boolean
function M.has(messages, filter, invert)
  return #M.filter(messages, filter, invert) > 0
end

return M
