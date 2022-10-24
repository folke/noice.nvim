local require = require("noice.util.lazy")

local Config = require("noice.config")
local Util = require("noice.util")
local Router = require("noice.message.router")
local Manager = require("noice.message.manager")

---@alias NoiceEvent MsgEvent|CmdlineEvent|NotifyEvent
---@alias NoiceKind MsgKind|NotifyLevel

local M = {}
M._attached = false
---@type table<string, any>
M._last = {}

function M.enable()
  local safe_handle = Util.protect(M.handle, { msg = "An error happened while handling a ui event" })
  M._attached = true

  local stack_level = 0

  vim.ui_attach(Config.ns, {
    ext_messages = Config.options.messages.enabled,
    ext_cmdline = Config.options.cmdline.enabled,
    ext_popupmenu = Config.options.popupmenu.enabled,
  }, function(event, ...)
    -- dont process any messages during redraw, since redraw triggers last messages
    -- if not Hacks.inside_redraw then
    if stack_level > 50 then
      Util.panic("Event loop detected. Shutting down...")
      return
    end
    stack_level = stack_level + 1

    local tick = Manager.tick()
    safe_handle(event, ...)

    -- check if we need to update the ui
    if Manager.tick() > tick then
      -- Util.debug(vim.inspect({ event, tick, ... }))
      if Util.is_blocking() then
        Util.try(Router.update)
      end
    else
      local handler = M.parse_event(event)
      Util.stats.track(handler .. ".skipped")
    end
    stack_level = stack_level - 1
  end)
end

function M.disable()
  if M._attached then
    vim.ui_detach(Config.ns)
    M._attached = false
  end
end

---@return string, string
function M.parse_event(event)
  return event:match("([a-z]+)_(.*)")
end

---@param event string
function M.handle(event, ...)
  local event_group, event_type = event:match("([a-z]+)_(.*)")
  local on = "on_" .. event_type

  local ok, handler = pcall(_G.require, "noice.ui." .. event_group)

  if not ok then
    if Config.options.debug then
      vim.schedule(function()
        Util.error("No ui router for " .. event_group)
      end)
    end
    return
  end

  if type(handler[on]) ~= "function" then
    local args = { ... }
    if Config.options.debug then
      vim.schedule(function()
        Util.error(
          "No ui router for **"
            .. event
            .. "** events\n```lua\n"
            .. vim.inspect({ group = event_group, on = on, args = args })
            .. "\n```"
        )
      end)
    end
    return
  end

  handler[on](event, ...)
end

return M
