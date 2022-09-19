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
	vim.cmd([[redraw]])
end

function M.handle(event, ...)
	if event == "msg_show" then
		-- M.handle_msg_show(...)
	elseif event == "msg_history_show" then
		M.handle_msg_history_show(...)
	end
end

function M.handle_msg_show(kind, content, replace_last)
	View.render(content)
end

function M.handle_msg_history_show(entries)
	local contents = {}
	for _, e in pairs(entries) do
		local kind, content = unpack(e)
		table.insert(contents, { 0, "" })
		vim.list_extend(contents, content)
	end
	View.render(contents)
end

function M.disable()
	if M.attached then
		vim.ui_detach(Config.ns)
		vim.opt.cmdheight = 1
		M.attached = false
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("messages_ui", {})

	vim.api.nvim_create_autocmd("CmdlineEnter", {
		group = group,
		callback = function()
			M.disable()
			vim.opt.cmdheight = 1
			vim.cmd([[redraw]])
		end,
	})

	vim.api.nvim_create_autocmd("CmdlineLeave", {
		group = group,
		callback = function()
			-- vim.schedule(M.enable)
			M.enable()
			vim.cmd([[redraw]])
		end,
	})
	M.enable()
end

View.show()
M.setup()

return M
