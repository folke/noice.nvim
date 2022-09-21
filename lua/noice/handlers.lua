local Highlight = require("noice.highlight")
local Config = require("noice.config")
local Render = require("noice.render")

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
	M.add({ event = "default", renderer = "popup" })
	M.add({ event = "msg_show", renderer = "notify" })
	M.add({ event = "msg_history_show", renderer = "popup" })
	M.add({
		event = { "msg_showmode", "msg_showcmd" },
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
	vim.defer_fn(M.run, Config.options.throttle)
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
