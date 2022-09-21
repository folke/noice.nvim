local Config = require("noice.config")
local Util = require("noice.util")

local M = {}

M.attached = false

function M.attach()
	M.attached = true
	vim.ui_attach(Config.ns, { ext_messages = true }, function(event, ...)
		M.handle(event, ...)
	end)
end

function M.detach()
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
			M.detach()
			-- vim.opt.cmdheight = 1
			vim.cmd([[redraw]])
		end,
	})

	vim.api.nvim_create_autocmd("CmdlineLeave", {
		group = group,
		callback = function()
			M.attach()
		end,
	})

	M.attach()
end

function M.handle(event, ...)
	local event_group, event_type = event:match("([a-z]+)_(.*)")
	local on = "on_" .. event_type

	local ok, handler = pcall(require, "noice.ui." .. event_group)
	if not (ok and type(handler[on]) == "function") then
		if Config.options.debug then
			Util.error("No ui handlers for **" .. event .. "** events\n```lua\n" .. vim.inspect({ ... }) .. "\n```")
		end
		return
	end

	handler[on](event, ...)
end

return M
