local Config = require("noice.config")
local Util = require("noice.util")
local View = require("noice.view")
local Manager = require("noice.manager")
local Instant = require("noice.instant")

---@class NoiceRoute
---@field view NoiceView
---@field filter NoiceFilter
---@field opts? NoiceRouteOptions|NoiceViewOptions

---@class NoiceRouteOptions
---@field history boolean
---@field stop boolean

---@class NoiceRouteConfig
---@field view string
---@field filter NoiceFilter
---@field opts? NoiceRouteOptions|NoiceViewOptions

local M = {}
M._running = false
---@type NoiceRoute[]
M._routes = {}
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

---@param route NoiceRouteConfig
function M.add(route)
  route.opts = route.opts or {}
  route.opts.title = route.opts.title or "Noice"

  local view = route.view
  if type(view) == "string" then
    route.view = View.get_view(route.view, route.opts)
  end
  table.insert(M._routes, route)
end

function M.setup()
  for _, route in ipairs(Config.options.routes) do
    M.add(route)
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
  for _, route in ipairs(M._routes) do
    local filter_opts = route.opts.history and { history = true, sort = true } or { messages = messages }
    local messages_view = Manager.get(route.filter, filter_opts)

    updated = updated + (route.view:display(messages_view) and 1 or 0)
    if route.opts.stop ~= false and route.opts.history ~= true then
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
