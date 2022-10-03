local require = require("noice.util.lazy")

local Message = require("noice.message")

local M = {}

---@class NoiceStat
---@field event string
---@field count number

---@type table<string, NoiceStat>
M._stats = {}

function M.reset()
  M._stats = {}
end

function M.track(event)
  if not M._stats[event] then
    M._stats[event] = {
      event = event,
      count = 0,
    }
  end
  M._stats[event].count = M._stats[event].count + 1
end

---@type NoiceMessage
M._message = nil
function M.message()
  if not M._message then
    M._message = Message("noice", "stats")
  end
  M._message:set(vim.inspect(M._stats))
  return M._message
end

return M
