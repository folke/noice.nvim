local function setup(opts)
	local Split = require("nui.split")
	local event = require("nui.utils.autocmd").event

	opts = vim.tbl_deep_extend("force", {}, {
		relative = "editor",
		position = "bottom",
		size = "20%",
		win_options = {
			winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
		},
	}, opts or {})

	local split = Split(opts)

	-- mount/open the component
	split:mount()

	-- unmount component when cursor leaves buffer
	split:on(event.BufLeave, function()
		split:unmount()
	end, { once = true })

	split:on({ event.BufWinLeave }, function()
		vim.schedule(function()
			split:unmount()
		end)
	end, { once = true })

	split:map("n", { "q", "<esc>" }, function()
		split:unmount()
	end, { remap = false, nowait = true })

	return split
end

---@param renderer Renderer
local function get_split(renderer)
	---@type NuiSplit
	local split = renderer.split
	if split and split.bufnr and vim.api.nvim_buf_is_valid(split.bufnr) then
		return split
	end

	renderer.split = setup({
		border = {
			text = { top = " Messages " },
		},
	})
	return renderer.split
end

---@param renderer Renderer
return function(renderer)
	renderer:render_buf(get_split(renderer).bufnr)
end
