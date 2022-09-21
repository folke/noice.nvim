local Config = require("noice.config")

local M = {}

function M.on_shddow(event, content, pos, firstc, prompt, indent, level)
	dumpp({ event, content, pos, firstc, prompt, indent, level })
end

return M
