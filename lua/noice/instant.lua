local Util = require("noice.util")

local M = {}
M._instant = false

function M.start()
  local instant = M._instant
  M._instant = true
  return {
    stop = function()
      M._instant = instant
    end,
  }
end

-- Check wether we are in an instant event, and not in a vim fast event
function M.in_instant()
  return M._instant and not vim.in_fast_event()
end

---@param fn fun():any
function M.run(fn, ...)
  local instant = M.start()
  local ret = Util.try(fn, ...)
  instant.stop()
  return ret
end

return M
