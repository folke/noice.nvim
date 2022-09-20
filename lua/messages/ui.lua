local Config = require("messages.config")
local View = require("messages.view")

local M = {
	attached = false,
}

function M.enable()
	M.attached = true
	vim.ui_attach(Config.ns, { ext_messages = true }, function(event, ...)
		M.handle(event, ...)
	end)
end

function M.handle(event, ...)
	if event == "msg_show" then
		M.handle_msg_show(event, ...)
	elseif event == "msg_showmode" then
		M.handle_msg_showmode(event, ...)
	elseif event == "msg_showcmd" then
		M.handle_msg_showcmd(event, ...)
	elseif event == "msg_clear" then
		View.queue({ event = "msg_clear" })
	elseif event == "return_prompt" then
	elseif event == "msg_history_show" then
		M.handle_msg_history_show(event, ...)
	end
end

function M.handle_msg_showmode(event, content)
	if vim.tbl_isempty(content) then
		View.queue({ event = event, clear = true })
	else
		View.queue({ event = event, chunks = content })
	end
end
M.handle_msg_showcmd = M.handle_msg_showmode

function M.handle_msg_show(event, kind, content, replace_last)
	if kind == "return_prompt" then
		vim.api.nvim_input("<cr>")
		return
	end
	local clear_kinds = { "echo", "search_count" }
	View.queue({ event = event, kind = kind, chunks = content, clear = vim.tbl_contains(clear_kinds, kind) })
end

function M.handle_msg_history_show(event, entries)
	local contents = {}
	for _, e in pairs(entries) do
		local _, content = unpack(e)
		table.insert(contents, { 0, "\n" })
		vim.list_extend(contents, content)
	end
	View.queue({ event = event, chunks = contents })
end

function M.disable()
	if M.attached then
		vim.ui_detach(Config.ns)
		M.attached = false
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("messages_ui", {})

	vim.api.nvim_create_autocmd("CmdlineEnter", {
		group = group,
		callback = function()
			M.disable()
			-- vim.opt.cmdheight = 1
			vim.cmd([[redraw]])
		end,
	})

	vim.api.nvim_create_autocmd("CmdlineLeave", {
		group = group,
		callback = function()
			M.enable()
		end,
	})
	M.enable()
end

return M
