local Highlight = require("messages.highlight")
local Config = require("messages.config")

local M = {}

---@class Highlight
---@field hl string
---@field line number
---@field from number
---@field to number

---@alias RenderFunc fun(renderer: Renderer, clear?: boolean)

---@class Renderer
---@field _render RenderFunc
---@field lines string[]
---@field highlights Highlight[]
---@field opts? table
---@field dirty boolean
---@field _clear boolean
local Renderer = {}
Renderer.__index = Renderer

---@param render string
---@param opts? table
function M.new(render, opts)
	return setmetatable({
		_render = M[render],
		opts = opts or {},
		dirty = false,
		lines = {},
		highlights = {},
	}, Renderer)
end

function Renderer:render()
	if self.dirty then
		local ok, err = pcall(self._render, self)
		if not ok then
			vim.notify(err, "error", { title = "Messages" })
		end
		self.dirty = false
	end
end

function Renderer:clear()
	self._clear = true
end

function Renderer:render_buf(buf, opts)
	opts = opts or {}
	if opts.lines ~= false then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, self.lines)
	end
	if opts.highlights ~= false then
		for _, hl in ipairs(self.highlights) do
			vim.api.nvim_buf_add_highlight(buf, Config.ns, hl.hl, hl.line + (opts.offset or 0), hl.from, hl.to)
		end
	end
	vim.cmd.redraw()
end

function Renderer:add(chunks)
	if self._clear then
		self.lines = {}
		self.highlights = {}
		self._clear = false
	end
	self.dirty = true
	for _, chunk in ipairs(chunks) do
		local attr_id, text = unpack(chunk)
		local hl = Highlight.get_hl(attr_id)

		-- M.status = M.status .. "%#" .. hl .. "#" .. text

		local function append(l)
			if #self.lines == 0 then
				table.insert(self.lines, "")
			end
			local line = self.lines[#self.lines]
			table.insert(self.highlights, {
				hl = hl,
				line = #self.lines - 1,
				from = #line,
				to = #line + #l,
			})
			self.lines[#self.lines] = line .. l
		end

		while text ~= "" do
			local nl = text:find("\n")
			if nl then
				local str = text:sub(1, nl - 1)
				append(str)
				table.insert(self.lines, "")
				text = text:sub(nl + 1)
			else
				append(text)
				text = ""
			end
		end
	end
end

setmetatable(M, {
	__index = function(_, key)
		return require("messages.render." .. key)
	end,
})

return M
