local Util = require("noice.util")

local M = {}

---@alias NoiceFilterFun fun(message: NoiceMessage, ...): boolean

---@class NoiceFilter
---@field event? NoiceEvent|NoiceEvent[]
---@field kind? NoiceKind|NoiceKind[]
---@field message? NoiceMessage
---@field any? NoiceFilter[]
---@field not? NoiceFilter
---@field min_height? integer
---@field max_height? integer
---@field find? string
---@field error? boolean
---@field warning? boolean
---@field mode? string
---@field blocking? boolean
---@field before_input? boolean

-----@type table<string, NoiceFilterFun>
M.filters = {
  mode = function(_, mode)
    return vim.api.nvim_get_mode().mode:find(mode)
  end,
  blocking = function(_, blocking)
    return blocking == Util.is_blocking()
  end,
  before_input = function(_, before_input)
    return before_input == require("noice.hacks").before_input
  end,
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
  error = function(message, error)
    local Msg = require("noice.ui.msg")
    ---@cast message NoiceMessage
    return error
      == (
        message.event == Msg.events.show
        and vim.tbl_contains(
          { Msg.kinds.echoerr, Msg.kinds.lua_error, Msg.kinds.rpc_error, Msg.kinds.emsg },
          message.kind
        )
      )
  end,
  warning = function(message, warning)
    local Msg = require("noice.ui.msg")
    ---@cast message NoiceMessage
    return warning == (message.event == Msg.events.show and vim.tbl_contains({ Msg.kinds.wmsg }, message.kind))
  end,
  find = function(message, find)
    ---@cast message NoiceMessage
    return message:content(true):find(find)
  end,
  min_height = function(message, min_height)
    ---@cast message NoiceMessage
    return message:height() >= min_height
  end,
  max_height = function(message, max_height)
    ---@cast message NoiceMessage
    return message:height() <= max_height
  end,
  any = function(message, any)
    ---@cast message NoiceMessage
    ---@cast any NoiceFilter[]
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
      Util.error("Unknown filter key " .. k .. " for " .. vim.inspect(filter))
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
  return vim.tbl_filter(
    ---@param message NoiceMessage
    function(message)
      local is = M.is(message, filter)
      if invert then
        is = not is
      end
      return is
    end,
    messages
  )
end

---@param messages NoiceMessage[]
---@param filter NoiceFilter
---@param invert? boolean
function M.has(messages, filter, invert)
  return #M.filter(messages, filter, invert) > 0
end

return M
