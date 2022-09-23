local Config = require("noice.config")
local Util = require("noice.util")
local View = require("noice.view")

local M = {}

---@type {filter: NoiceFilter, view: NoiceView, opts: table}[]
M.handlers = {
  default = View(function() end),
}

---@param handler NoiceHandler
function M.add(handler)
  handler.opts = handler.opts or {}
  handler.opts.title = handler.opts.title or "Noice"

  local view = handler.view
  if type(view) == "string" then
    handler.view = View(view, handler.opts)
  end
  table.insert(M.handlers, handler)
end

---@param message NoiceMessage
function M.get(message)
  for _, handler in ipairs(M.handlers) do
    if message:is(handler.filter) then
      return handler.view
    end
  end
  return nil
end

---@class NoiceHandler
---@field filter NoiceFilter
---@field view string|NoiceView
---@field opts? table

function M.setup()
  M.add({
    view = "cmdline",
    filter = { event = "cmdline" },
    opts = { filetype = "vim" },
  })
  M.add({
    view = "cmdline",
    filter = { event = "msg_show", kind = "confirm" },
  })
  M.add({
    view = "split",
    filter = {
      any = {
        { event = "msg_history_show" },
        -- { min_height = 20 },
      },
    },
  })
  M.add({
    view = "virtualtext",
    filter = {
      event = "msg_show",
      kind = "search_count",
    },
  })
  M.add({
    view = "nop", -- use statusline components instead
    filter = {
      any = {
        { event = { "msg_showmode", "msg_showcmd", "msg_ruler" } },
        { event = "msg_show", kind = "search_count" },
      },
    },
    opts = { level = vim.log.levels.WARN },
  })
  M.add({
    view = "notify",
    filter = {
      event = "msg_show",
      kind = { "echoerr", "lua_error", "rpc_error", "emsg" },
    },
    opts = { level = vim.log.levels.ERROR, replace = false },
  })
  M.add({
    view = "notify",
    filter = {
      event = "msg_show",
      kind = "wmsg",
    },
    opts = { level = vim.log.levels.WARN, replace = false },
  })
  M.add({
    view = "notify",
    filter = {},
  })

  vim.schedule(M.run)
end

---@class MessageEvent
---@field message? NoiceMessage
---@field remove? NoiceFilter
---@field clear? NoiceFilter
---@field nowait? boolean
M.event_keys = { "message", "remove", "clear", "nowait" }

local function do_action(action, ...)
  for _, handler in ipairs(M.handlers) do
    handler.view[action](handler.view, ...)
  end
end

---@param event MessageEvent
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
    if view then
      view:add(event.message)
    end
    return view
  end
end

---@param event MessageEvent
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
      for _, r in ipairs(M.handlers) do
        rendered = rendered + (r.view:update() and 1 or 0)
      end
      if rendered > 0 then
        require("noice.ui").redraw()
      end
    end)
  )
end

return M
