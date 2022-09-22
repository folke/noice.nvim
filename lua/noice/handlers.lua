local Config = require("noice.config")
local Render = require("noice.render")

local M = {}

---@type table<string, Renderer>
M.handlers = {
  default = Render.new(function() end),
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

---@param handler MessageHandler
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

      local renderer = handler.renderer
      if type(renderer) == "string" then
        renderer = Render.new(renderer, opts)
      end
      M.handlers[hid] = renderer
    end
  end
end

---@class MessageHandler
---@field event string|string[]
---@field kind? string|string[]
---@field renderer string|Renderer
---@field opts? table

function M.setup()
  M.add({ event = "default", renderer = "split" })
  M.add({ event = "msg_show", renderer = "split" })
  M.add({ event = "msg_show", kind = { "echo", "echomsg", "", "search_count" }, renderer = "notify" })
  M.add({ event = "msg_show", kind = "confirm", renderer = "cmdline" })
  M.add({ event = "cmdline", renderer = "cmdline" })
  M.add({ event = "msg_history_show", renderer = "split" })
  M.add({
    event = { "msg_showmode", "msg_showcmd", "msg_ruler" },
    renderer = "notify",
    opts = { level = vim.log.levels.WARN },
  })
  M.add({
    event = "msg_show",
    kind = { "echoerr", "lua_error", "rpc_error", "emsg" },
    renderer = "notify",
    opts = { level = vim.log.levels.ERROR, replace = false },
  })
  M.add({
    event = "msg_show",
    kind = "wmsg",
    renderer = "notify",
    opts = { level = vim.log.levels.WARN, replace = false },
  })
  vim.schedule(M.run)
end

---@class RenderEvent
---@field event string
---@field chunks? table
---@field opts? table
---@field highlights? table
---@field clear? boolean
---@field hide? boolean
---@field show? boolean
---@field nowait? boolean

local function msg_clear()
  for k, r in pairs(M.handlers) do
    if k:find("msg_show") == 1 then
      r:clear()
    end
  end
end

---@param event RenderEvent
local function process(event)
  if event.event == "msg_clear" then
    msg_clear()
  else
    local renderer = M.get(event)
    if event.opts then
      renderer.opts = vim.tbl_deep_extend("force", renderer.opts, event.opts)
    end
    if event.clear then
      renderer:clear()
    end
    if event.hide then
      renderer:hide()
    end
    if event.show then
      renderer:show()
    end
    if event.chunks then
      renderer:add(event.chunks)
    end
    return renderer
  end
end

---@param event RenderEvent
function M.handle(event)
  if event.nowait then
    if process(event):render() then
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
        rendered = rendered + (r:render() and 1 or 0)
      end
      if rendered > 0 then
        require("noice.ui").redraw()
      end
    end)
  )
end

return M
