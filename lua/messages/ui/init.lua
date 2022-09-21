local Config = require("messages.config")
local View = require("messages.view")
local Messages = require("messages.ui.messages")

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
	if event:find("msg_") == 1 then
		Messages.handle(event, ...)
	end
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
