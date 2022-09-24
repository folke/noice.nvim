local Config = require("noice.config")
local Util = require("noice.util")
local Handlers = require("noice.handlers")

---@class uv.Timer
---@field start fun(timer:uv.Timer, timeout: number, repeat: number, callback: fun())
---@field stop fun(timer: uv.Timer)

local M = {}
M._instant = false
M._queue = {}
---@type uv.Timer?
M._timer = nil

---@type NoiceFilter
M._instant_filter = {
  any = {
    { event = "msg_show", find = "E325" },
    { event = "msg_show", find = "Found a swap file" },
  },
}

function M.start()
  M._timer = vim.loop.new_timer()
  local cb = vim.schedule_wrap(M.process_queue)
  ---@cast cb fun()
  M._timer:start(Config.options.throttle, Config.options.throttle, cb)
end

function M.stop()
  M._timer:stop()
  M._timer = nil
end

-- Check wether we are in an instant event, and not in a vim fast event
function M.in_instant_event()
  return M._instant
end

-- Runs fn if supplied and processes all events during this tick
---@param fn? fun()
function M.run_instant(fn, ...)
  local instant = M._instant
  M._instant = true
  Util.try(M.process_queue)
  local ret = fn and Util.try(fn, ...)
  M._instant = instant
  return ret
end

function M.setup()
  -- TODO: PR for notify static on message
  -- TODO: echo and echom for input

  vim.schedule(M.start)
end

---@param event MessageEvent
function M.schedule(event)
  local instant = event.instant or (event.message and event.message:is(M._instant_filter))

  if instant and not vim.in_fast_event() then
    table.insert(M._queue, event)
    M.run_instant(M.process_queue)
  else
    table.insert(M._queue, event)
  end
end

function M.process_queue()
  while #M._queue > 0 do
    Handlers.process(table.remove(M._queue, 1))
  end
  local rendered = 0
  for _, handler in ipairs(Handlers.handlers) do
    rendered = rendered + (handler.view:update() and 1 or 0)
  end
  if rendered > 0 then
    require("noice.ui").redraw()
  end
end

return M
