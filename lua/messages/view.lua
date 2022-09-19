local Highlight = require("messages.highlight")
local Config = require("messages.config")

local M = {
	buf = nil,
	win = nil,
}

function M.show()
	M.buf = vim.api.nvim_create_buf(false, true)
	M.win = vim.api.nvim_open_win(M.buf, false, {
		relative = "editor",
		focusable = false,
		width = 40,
		height = 10,
		anchor = "NE",
		row = 1,
		col = vim.o.columns,
		style = "minimal",
		border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
	})
end

function M.render(chunks)
	local lines = { "" }
	local highlights = {}
	for _, chunk in ipairs(chunks) do
		local attr_id, text = unpack(chunk)
		local hl = Highlight.get_hl(attr_id)
		for _, l in ipairs(vim.fn.split(text, "\n", true)) do
			if l == "" then
				table.insert(lines, "")
			else
				local line = lines[#lines]
				table.insert(highlights, {
					hl = hl,
					line = #lines - 1,
					from = #line,
					to = #line + #l,
				})
				lines[#lines] = line .. l
			end
		end
	end

	vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
	dumpp(highlights)
	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(M.buf, Config.ns, hl.hl, hl.line, hl.from, hl.to)
	end
end

return M
