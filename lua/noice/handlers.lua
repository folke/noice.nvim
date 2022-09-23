local Config = require("noice.config")
local Util = require("noice.util")
local View = require("noice.view")
local Message = require("noice.message")

local M = {}

---@type table<string, noice.View>
M.handlers = {
  default = View(function() end),
}

---@param opts? {event: string, kind?:string}
local function id(opts)
  opts = opts or { event = "default" }
  return opts.event .. (opts.kind and ("." .. opts.kind) or "")
end

---@param opts? {event: string, kind?:string}
function M.get(opts)
  opts = opts or { event = "default" }
  return M.handlers[id(opts)] or M.handlers[opts.event] or M.handlers.default
end

---@param handler NoiceMessageHandler
function M.add(handler)
  local events = handler.event
  if type(events) ~= "table" then
    events = { events }
  end

  local kinds = handler.kind
  if type(kinds) ~= "table" then
    kinds = { kinds }
  end

  for _, event in ipairs(events) do
    -- handle special case where kind = nil
    for k = 1, math.max(#kinds, 1) do
      local kind = kinds[k]
      local hid = id({ event = event, kind = kind })

      local opts = vim.deepcopy(handler.opts or {})
      opts.title = opts.title or "Noice"
      if Config.options.debug then
        opts.title = opts.title .. " (" .. hid .. ")"
      end

      local view = handler.view
      if type(view) == "string" then
        view = View(view, opts)
      end
      M.handlers[hid] = view
    end
  end
end

---@class NoiceMessageHandler
---@field event string|string[]
---@field kind? string|string[]
---@field view string|noice.View
---@field opts? table

function M.setup()
  M.add({ event = "default", view = "notify" })
  -- M.add({ event = "msg_show", view = "split" })
  -- M.add({ event = "msg_show", kind = { "echo", "echomsg", "", "search_count" }, view = "notify" })
  -- M.add({ event = "msg_show", kind = "confirm", view = "cmdline" })
  M.add({ event = "cmdline", view = "cmdline", opts = { filetype = "vim" } })
  M.add({ event = "msg_history_show", view = "split" })
  -- M.add({
  --   event = { "msg_showmode", "msg_showcmd", "msg_ruler" },
  --   view = "notify",
  --   opts = { level = vim.log.levels.WARN },
  -- })
  -- M.add({
  --   event = "msg_show",
  --   kind = { "echoerr", "lua_error", "rpc_error", "emsg" },
  --   view = "notify",
  --   opts = { level = vim.log.levels.ERROR, replace = false },
  -- })
  -- M.add({
  --   event = "msg_show",
  --   kind = "wmsg",
  --   view = "notify",
  --   opts = { level = vim.log.levels.WARN, replace = false },
  -- })
  vim.schedule(M.run)
end

---@class noice.RenderEvent
---@field message? NoiceMessage
---@field remove? NoiceMessage|NoiceFilter
---@field clear? NoiceMessage|NoiceFilter
---@field nowait? boolean
M.event_keys = { "message", "remove", "clear", "nowait" }

local function do_action(action, ...)
  for _, view in pairs(M.handlers) do
    view[action](view, ...)
  end
end

---@param event noice.RenderEvent
local function process(event)
  for k, _ in pairs(event) do
    if not vim.tbl_contains(M.event_keys, k) then
      Util.error("Invalid event " .. vim.inspect(event))
      return
    end
  end

  if event.remove then
    do_action("remove", event.remove)
  end

  if event.clear then
    do_action("clear", event.clear)
  end

  if event.message then
    local view = M.get(event.message)
    view:add(event.message)
    return view
  end
end

---@param event noice.RenderEvent
function M.handle(event)
  if event.nowait then
    local view = process(event)
    if view and view:update() then
      require("noice.ui").redraw()
    end
  else
    table.insert(M._queue, event)
  end
end

M.running = false
M._queue = {}

function M.run()
  M.running = true

  vim.loop.new_timer():start(
    Config.options.throttle,
    Config.options.throttle,
    vim.schedule_wrap(function()
      while #M._queue > 0 do
        process(table.remove(M._queue, 1))
      end
      local rendered = 0
      for _, r in pairs(M.handlers) do
        rendered = rendered + (r:update() and 1 or 0)
      end
      if rendered > 0 then
        require("noice.ui").redraw()
      end
    end)
  )
end

return M
