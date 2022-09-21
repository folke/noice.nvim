local View = require("noice.view")

local M = {}

function M.on_clear()
	View.queue({ event = "msg_clear" })
end

function M.on_showmode(event, content)
	if vim.tbl_isempty(content) then
		View.queue({ event = event, clear = true })
	else
		View.queue({ event = event, chunks = content, clear = true })
	end
end
M.on_showcmd = M.on_showmode

function M.on_show(event, kind, content, replace_last)
	if kind == "return_prompt" then
		vim.api.nvim_input("<cr>")
		return
	end
	if kind == "confirm" then
		return M.on_confirm()
	end
	local clear_kinds = { "echo" }
	local clear = replace_last or vim.tbl_contains(clear_kinds, kind)
	View.queue({
		event = event,
		kind = kind,
		chunks = content,
		clear = clear,
		nowait = (kind == "confirm"),
	})
end

function M.on_confirm()
	-- detach and reattach on the next schedule, so the user can do the confirmation
	local ui = require("noice.ui")
	ui.detach()
	vim.schedule(function()
		ui.attach()
	end)
end

function M.on_history_show(event, entries)
	local contents = {}
	for _, e in pairs(entries) do
		local _, content = unpack(e)
		table.insert(contents, { 0, "\n" })
		vim.list_extend(contents, content)
	end
	View.queue({ event = event, chunks = contents })
end

return M
