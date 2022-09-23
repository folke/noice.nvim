local Util = require("noice.util")

local M = {}

---@alias NoiceFilterFun fun(message: NoiceMessage, ...): boolean

---@class NoiceFilter
---@field event? NoiceEvent|NoiceEvent[]
---@field kind? NoiceKind|NoiceKind[]
---@field message? NoiceMessage
---@field keep? boolean
---@field any? NoiceFilter[]
---@field not? NoiceFilter
---@field min_height? integer

-----@type table<string, NoiceFilterFun>
M.filters = {
  event = function(message, event)
    ---@cast message NoiceMessage
    event = type(event) == "table" and event or { event }
    return vim.tbl_contains(event, message.event)
  end,
  kind = function(message, kind)
    ---@cast message NoiceMessage
    kind = type(kind) == "table" and kind or { kind }
    return vim.tbl_contains(kind, message.kind)
  end,
  message = function(message, other)
    ---@cast message NoiceMessage
    return other == message
  end,
  keep = function(message, keep)
    ---@cast message NoiceMessage
    return message.keep == keep
  end,
  min_height = function(message, min_height)
    ---@cast message NoiceMessage
    return message:height() >= min_height
  end,
  any = function(message, any)
    ---@cast message NoiceMessage
    for _, f in ipairs(any) do
      if message:is(f) then
        return true
      end
    end
    return false
  end,
  ["not"] = function(message, filter)
    ---@cast message NoiceMessage
    return not message:is(filter)
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
