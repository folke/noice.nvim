local require = require("noice.util.lazy")

local Config = require("noice.config")
local Util = require("noice.util")
local Hacks = require("noice.hacks")
local Router = require("noice.router")

---@alias NoiceEvent MsgEvent|CmdlineEvent
---@alias NoiceKind MsgKind

local M = {}
M._attached = false

function M.attach()
  local safe_handle = Util.protect(M.handle, { msg = "An error happened while handling a ui event" })
  M._attached = true
  vim.ui_attach(Config.ns, {
    ext_messages = true,
    ext_cmdline = true,
    ext_popupmenu = true,
  }, function(event, ...)
    if not Hacks.inside_redraw then
      safe_handle(event, ...)
    end

    if Util.is_blocking() and not Hacks.block_redraw then
      Util.try(Router.update)
    end
  end)
end

function M.detach()
  if M._attached then
    vim.ui_detach(Config.ns)
    M._attached = false
  end
end

function M.setup()
  M.attach()
end

---@param event string
function M.handle(event, ...)
  local event_group, event_type = event:match("([a-z]+)_(.*)")
  local on = "on_" .. event_type

  local ok, handler = pcall(require, "noice.ui." .. event_group)
  if not (ok and type(handler[on]) == "function") then
    if Config.options.debug then
      Util.error("No ui router for **" .. event .. "** events\n```lua\n" .. vim.inspect({ ... }) .. "\n```")
    end
    return
  end

  handler[on](event, ...)
end

return M
