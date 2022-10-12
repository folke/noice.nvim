local require = require("noice.util.lazy")

local Config = require("noice.config")
local Util = require("noice.util")
local Hacks = require("noice.util.hacks")
local Router = require("noice.message.router")

---@alias NoiceEvent MsgEvent|CmdlineEvent|NotifyEvent
---@alias NoiceKind MsgKind|NotifyLevel

local M = {}
M._attached = false

function M.enable()
  local safe_handle = Util.protect(M.handle, { msg = "An error happened while handling a ui event" })
  M._attached = true

  ---@type any?
  local last_msg = nil

  vim.ui_attach(Config.ns, {
    ext_messages = Config.options.messages.enabled,
    ext_cmdline = Config.options.cmdline.enabled,
    ext_popupmenu = Config.options.popupmenu.enabled,
  }, function(event, ...)
    local msg = { event, ... }

    if Config.options.hacks.skip_duplicate_messages and vim.deep_equal(last_msg, msg) then
      return
    end
    last_msg = msg
    -- dont process any messages during redraw, since redraw triggers last messages
    if not Hacks.inside_redraw then
      safe_handle(event, ...)

      -- check if we need to update the ui
      if Util.is_blocking() then
        Util.try(Router.update)
      end
    end
  end)
end

function M.disable()
  if M._attached then
    vim.ui_detach(Config.ns)
    M._attached = false
  end
end

---@param event string
function M.handle(event, ...)
  local event_group, event_type = event:match("([a-z]+)_(.*)")
  local on = "on_" .. event_type

  local ok, handler = pcall(_G.require, "noice.ui." .. event_group)
  if not (ok and type(handler[on]) == "function") then
    if Config.options.debug then
      Util.error("No ui router for **" .. event .. "** events\n```lua\n" .. vim.inspect({ ... }) .. "\n```")
    end
    return
  end

  handler[on](event, ...)
end

return M
