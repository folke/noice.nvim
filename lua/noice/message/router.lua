local require = require("noice.util.lazy")

local Config = require("noice.config")
local Util = require("noice.util")
local View = require("noice.view")
local Manager = require("noice.message.manager")

---@class NoiceRoute
---@field view NoiceView
---@field filter NoiceFilter
---@field opts? NoiceRouteOptions|NoiceViewOptions

---@class NoiceRouteOptions
---@field history boolean
---@field stop boolean
---@field skip boolean

---@class NoiceRouteConfig
---@field view string
---@field filter NoiceFilter
---@field opts? NoiceRouteOptions|NoiceViewOptions

local M = {}
M._running = false
---@type NoiceRoute[]
M._routes = {}
M._tick = 0
M._need_redraw = false

local function run()
  if not M._running then
    return
  end
  Util.try(M.update)
  vim.defer_fn(run, Config.options.throttle)
end

function M.enable()
  M._running = true
  vim.schedule(run)
end

function M.disable()
  M._running = false
  Manager.clear()
  M.update()
end

---@param route NoiceRouteConfig
function M.add(route)
  local ret = {
    filter = route.filter,
    opts = route.opts or {},
    view = route.view and View.get_view(route.view, route.opts) or nil,
  }
  if ret.view == nil then
    ret.view = nil
    ret.opts.skip = true
  end
  table.insert(M._routes, ret)
end

function M.setup()
  for _, route in ipairs(Config.options.routes) do
    M.add(route)
  end
end

function M.check_redraw()
  if Util.is_blocking() and M._need_redraw then
    -- NOTE: set to false before actually calling redraw to prevent a loop with ui
    M._need_redraw = false
    Util.redraw()
  end
end

function M.update()
  -- only update on changes
  if M._tick == Manager.tick() then
    M.check_redraw()
    return
  end

  Util.stats.track("router.update")

  ---@type table<NoiceView,NoiceMessage[]>
  local updates = {}
  ---@type table<NoiceView,NoiceViewOptions>
  local updates_opts = {}

  local updated = 0
  local messages = Manager.get(nil, { sort = true })
  for _, route in ipairs(M._routes) do
    local route_message_opts = route.opts.history and { history = true, sort = true } or { messages = messages }
    local route_messages = Manager.get(route.filter, route_message_opts)

    if not route.opts.skip then
      updates[route.view] = updates[route.view] or {}
      if #route_messages > 0 then
        updates_opts[route.view] = vim.tbl_deep_extend("force", updates_opts[route.view] or {}, route.opts)
      end
      vim.list_extend(updates[route.view], route_messages)
    end

    if route.opts.stop ~= false and route.opts.history ~= true then
      messages = vim.tbl_filter(
        ---@param me NoiceMessage
        function(me)
          return not vim.tbl_contains(route_messages, me)
        end,
        messages
      )
    end
  end

  for view, view_messages in pairs(updates) do
    view._route_opts = updates_opts[view]
    updated = updated + (view:display(view_messages) and 1 or 0)
    for _, m in ipairs(view_messages) do
      if m.once then
        Manager.clear({ message = m })
      end
    end
  end

  M._tick = Manager.tick()

  if updated > 0 then
    Util.stats.track("router.update.updated")
    M._need_redraw = true
  end

  M.check_redraw()

  return updated
end

return M
