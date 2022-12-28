local require = require("noice.util.lazy")

local Util = require("noice.util")
local Manager = require("noice.message.manager")

local M = {}

---@alias NoiceFilterFun fun(message: NoiceMessage, ...): boolean

---@class NoiceFilter
---@field any? NoiceFilter[]
---@field blocking? boolean
---@field cleared? boolean
---@field cmdline? string|boolean
---@field error? boolean
---@field event? NoiceEvent|NoiceEvent[]
---@field find? string
---@field has? boolean
---@field kind? NoiceKind|NoiceKind[]
---@field max_height? integer
---@field max_length? integer
---@field max_width? integer
---@field message? NoiceMessage|NoiceMessage[]
---@field min_height? integer
---@field min_length? integer
---@field min_width? integer
---@field mode? string
---@field not? NoiceFilter
---@field warning? boolean
---@field cond? fun(message:NoiceMessage):boolean

-----@type table<string, NoiceFilterFun>
M.filters = {
  cleared = function(message, cleared)
    ---@cast message NoiceMessage
    return cleared == not Manager.has(message)
  end,
  has = function(message, has)
    ---@cast message NoiceMessage
    return has == Manager.has(message, { history = true })
  end,
  cond = function(message, cond)
    return cond(message)
  end,
  mode = function(_, mode)
    return vim.api.nvim_get_mode().mode:find(mode)
  end,
  blocking = function(_, blocking)
    return blocking == Util.is_blocking()
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
  cmdline = function(message, cmdline)
    ---@cast message NoiceMessage
    ---@cast cmdline string|boolean
    if type(cmdline) == "boolean" then
      return (message.cmdline ~= nil) == cmdline
    end
    if message.cmdline then
      local str = message.cmdline.state.firstc .. message.cmdline:get()
      return str:find(cmdline)
    end
    return false
  end,
  message = function(message, other)
    ---@cast message NoiceMessage
    other = vim.tbl_islist(other) and other or { other }
    ---@cast other NoiceMessage[]
    for _, m in ipairs(other) do
      if m.id == message.id then
        return true
      end
    end
    return false
  end,
  error = function(message, error)
    ---@cast message NoiceMessage
    return error == (message.level == "error")
  end,
  warning = function(message, warning)
    ---@cast message NoiceMessage
    return warning == (message.level == "warn")
  end,
  find = function(message, find)
    ---@cast message NoiceMessage
    return message:content():find(find)
  end,
  min_height = function(message, min_height)
    ---@cast message NoiceMessage
    return message:height() >= min_height
  end,
  max_height = function(message, max_height)
    ---@cast message NoiceMessage
    return message:height() <= max_height
  end,
  min_width = function(message, min_width)
    ---@cast message NoiceMessage
    return message:width() >= min_width
  end,
  max_width = function(message, max_width)
    ---@cast message NoiceMessage
    return message:width() <= max_width
  end,
  min_length = function(message, min_length)
    ---@cast message NoiceMessage
    return message:length() >= min_length
  end,
  max_length = function(message, max_length)
    ---@cast message NoiceMessage
    return message:length() <= max_length
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

---@type table<string,boolean>
M._unknown_notified = {}

---@param message NoiceMessage
---@param filter NoiceFilter
function M.is(message, filter)
  for k, v in pairs(filter) do
    if M.filters[k] then
      if not M.filters[k](message, v) then
        return false
      end
    else
      if not M._unknown_notified[k] then
        M._unknown_notified[k] = true
        Util.error("Unknown filter key " .. k .. " for " .. vim.inspect(filter))
      end
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
