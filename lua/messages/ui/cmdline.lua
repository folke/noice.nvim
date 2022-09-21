local Config = require("messages.config")
local View = require("messages.view")

local M = {}

function M.handle(event, ...)
	if event == "cmdline_show" then
		M.on_show(event, ...)
	end
end

function M.on_show(event, content, pos, firstc, prompt, indent, level) end

return M
