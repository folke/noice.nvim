local Highlight = require("messages.highlight")
local Config = require("messages.config")
local Render = require("messages.render")

local M = {}

---@type table<string, Renderer>
M.handlers = {}

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
	local opts = handler.opts or {}
	opts.title = "Messages " .. id(handler)
	local renderer = handler.renderer
	if type(renderer) == "string" then
		renderer = Render.new(renderer, opts)
	end
	M.handlers[id(handler)] = renderer
end

---@class MessageHandler
---@field event string
---@field kind? string
---@field renderer string|Renderer
---@field opts? table

function M.setup()
	M.add({ event = "default", renderer = "float" })
	M.add({ event = "msg_show", renderer = "notify" })
	M.add({
		event = "msg_showmode",
		renderer = "notify",
		opts = { level = vim.log.levels.WARN },
	})
	M.add({
		event = "msg_showcmd",
		renderer = "notify",
		opts = { level = vim.log.levels.WARN },
	})
	M.add({
		event = "msg_show",
		kind = "echoerr",
		renderer = "notify",
		opts = { level = vim.log.levels.ERROR, replace = false },
	})
	M.add({
		event = "msg_show",
		kind = "lua_error",
		renderer = "notify",
		opts = { level = vim.log.levels.ERROR, replace = false },
	})
	M.add({
		event = "msg_show",
		kind = "rpc_error",
		renderer = "notify",
		opts = { level = vim.log.levels.ERROR, replace = false },
	})
	M.add({
		event = "msg_show",
		kind = "emsg",
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

M._queue = {}
M.running = false

function M.run()
	M.running = true
	while #M._queue > 0 do
		local opts = table.remove(M._queue, 1)
		if opts.event == "msg_clear" then
			M.msg_clear()
		end
		if opts.clear then
			M.get(opts):clear()
		end
		if opts.chunks then
			M.get(opts):add(opts.chunks)
		end
	end
	for _, r in pairs(M.handlers) do
		r:render()
	end
	vim.defer_fn(M.run, 100)
end

---@param opts { event: string, kind?: string, chunks: table}
function M.queue(opts)
	table.insert(M._queue, opts)
end

function M.msg_clear()
	for k, r in pairs(M.handlers) do
		if k:find("msg_show") == 1 then
			r:clear()
		end
	end
end

return M
