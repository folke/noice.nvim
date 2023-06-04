local require = require("noice.util.lazy")

local Config = require("noice.config")
local Util = require("noice.util")
local Router = require("noice.message.router")
local Manager = require("noice.message.manager")
local Hacks = require("noice.util.hacks")

---@alias NoiceEvent MsgEvent|CmdlineEvent|NotifyEvent|LspEvent
---@alias NoiceKind MsgKind|NotifyLevel|LspKind

local M = {}
M._attached = false

---@type table<string, table|false>
M._handlers = {}

function M.setup()
  local widgets = {
    messages = "msg",
    cmdline = "cmdline",
    popupmenu = "popupmenu",
    select = false,
  }

  -- Check if we're running inside a GUI that already externalizes some widgets
  ---@type table<string, boolean>
  local ui_widgets = {}
  local uis = vim.api.nvim_list_uis()
  for _, ui in ipairs(uis) do
    for ext, _ in pairs(widgets) do
      if ui["ext_" .. ext] then
        ui_widgets[ext] = true
      end
    end
  end

  M._handlers = {}

  ---@type table<string, boolean>
  local options = {}
  for ext, widget in pairs(widgets) do
    local load = widget
    if not load then
      load = ext
    end

    -- only enable if configured and not enabeled in the GUI
    if Config.options[ext].enabled and not ui_widgets[ext] then
      if widget then
        -- don't provide fake providers to nvim
        options["ext_" .. ext] = true
      end
      M._handlers[load] = _G.require("noice.ui." .. load)
    else
      if ui_widgets[ext] and Config.options.debug then
        Util.warn("Disabling ext_" .. load)
      end
      M._handlers[load] = false
    end
  end

  return options
end

function M.enable()
  local options = M.setup()

  if vim.tbl_isempty(options) then
    if Config.options.debug then
      vim.schedule(function()
        Util.warn("No extensions enabled")
      end)
    end
    return
  end

  local safe_handle = Util.protect(M.handle, { msg = "An error happened while handling a ui event" })
  M._attached = true

  local stack_level = 0
  local function raise_event(event, ...)
    local handler = M.get_handler(event, ...)

    if not handler then
      return false
    end

    if stack_level > 50 then
      Util.panic("Event loop detected. Shutting down...")
      return
    end
    stack_level = stack_level + 1

    local tick = Manager.tick()
    safe_handle(handler, event, ...)

    -- check if we need to update the ui
    if Manager.tick() > tick then
      -- Util.debug(vim.inspect({ event, Util.is_blocking(), tick, kind, ... }))
      if Util.is_blocking() then
        -- if event ~= "msg_show" then
        Util.try(Router.update)
        -- end
      end
    else
      local widget = M.parse_event(event)
      Util.stats.track(widget .. ".skipped")
    end
    stack_level = stack_level - 1

    return true
  end

  ---@diagnostic disable-next-line: redundant-parameter
  vim.ui_attach(Config.ns, options, function(event, ...)
    if Util.is_exiting() then
      return true
    end

    if not raise_event(event, ...) then
      return
    end

    -- work-around for segfaults with TUI rework
    -- this will block other uis from processing this message (being TUI) again
    -- Will be false for GUI so that they can still prcess the message as well
    local ui = vim.api.nvim_list_uis()[1]
    return ui and ui.chan == 1 and ui.ext_termcolors
  end)

  if M._handlers["select"] and vim.ui.select and not M._original_select then
    M._original_select = vim.ui.select
    vim.ui.select = function(...)
      if not raise_event("select_show", ...) then
        M._original_select(...)
      end
    end
  end

  vim.api.nvim_create_autocmd("SwapExists", {
    group = vim.api.nvim_create_augroup("noice-swap-exists", { clear = true }),
    callback = function()
      Util.try(Router.update)
    end,
  })
end

function M.redirect()
  M.disable()
  Router.echo_pending()
  vim.schedule(M.enable)
end

function M.disable()
  if M._original_select then
    vim.ui.select = M._original_select
    M._original_select = nil
  end
  if M._attached then
    M._attached = false
    vim.ui_detach(Config.ns)
  end
end

---@return string, string
function M.parse_event(event)
  return event:match("([a-z]+)_(.*)")
end

---@param event string
function M.get_handler(event, ...)
  local event_group, event_type = event:match("([a-z]+)_(.*)")
  local on = "on_" .. event_type

  local handler = M._handlers[event_group]

  -- false means this is a disabled handler
  if handler == false then
    return
  end

  if not handler then
    if Config.options.debug then
      vim.schedule(function()
        Util.error_once("No ui router for " .. event_group)
      end)
    end
    return
  end

  if type(handler[on]) ~= "function" then
    local args = { ... }
    if Config.options.debug then
      vim.schedule(function()
        Util.error_once(
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

  return handler[on]
end

---@param handler fun(...)
---@param event string
function M.handle(handler, event, ...)
  handler(event, ...)
end

return M
