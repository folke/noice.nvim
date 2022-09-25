local Config = require("noice.config")
local Util = require("noice.util")
local View = require("noice.view")
local Manager = require("noice.manager")
local Instant = require("noice.instant")

local M = {}
M._running = false
---@type {filter: NoiceFilter, view: NoiceView, opts: table}[]
M._handlers = {}
M._tick = 0

local function run()
  if not M._running then
    return
  end
  Util.try(M.update)
  vim.defer_fn(run, Config.options.throttle)
end

function M.start()
  M._running = true
  vim.schedule(run)
end

function M.stop()
  M._running = false
end

---@param handler NoiceHandler
function M.add(handler)
  handler.opts = handler.opts or {}
  handler.opts.title = handler.opts.title or "Noice"

  local view = handler.view
  if type(view) == "string" then
    handler.view = View(view, handler.opts)
  end
  table.insert(M._handlers, handler)
end

---@class NoiceHandler
---@field filter NoiceFilter
---@field view string|NoiceView
---@field opts? table

function M.setup()
  for _, handler in ipairs(Config.options.handlers) do
    M.add(handler)
  end
  vim.schedule(M.start)
end

---@param opts? { instant: boolean }
function M.update(opts)
  -- only update on changes
  if M._tick == Manager.tick() then
    return
  end

  opts = opts or {}
  local instant = (opts.instant or Instant.in_instant()) and Instant:start()
  local updated = 0
  local messages = Manager.get(nil, { sort = true })
  for _, handler in ipairs(M._handlers) do
    local messages_view = Manager.get(handler.filter, { messages = messages })
    updated = updated + (handler.view:display(messages_view) and 1 or 0)
    if handler.opts.stop ~= false then
      messages = vim.tbl_filter(function(me)
        return not vim.tbl_contains(messages_view, me)
      end, messages)
    end
  end

  if instant then
    if updated > 0 then
      require("noice.ui").redraw()
    end
    instant.stop()
  end
  M._tick = Manager.tick()
  return updated
end

return M
