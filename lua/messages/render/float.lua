local function setup(opts)
	local Popup = require("nui.popup")
	local event = require("nui.utils.autocmd").event

	opts = vim.tbl_deep_extend("force", {}, {
		enter = true,
		focusable = true,
		border = {
			style = "rounded",
		},
		position = "50%",
		size = {
			width = "80%",
			height = "60%",
		},
		win_options = {
			winhighlight = "Normal:NotifyINFOBody,FloatBorder:NotifyINFOBorder",
		},
	}, opts or {})

	local popup = Popup(opts)
	popup.border:set_highlight("NotifyINFOTitle")

	-- mount/open the component
	popup:mount()

	-- unmount component when cursor leaves buffer
	popup:on(event.BufLeave, function()
		popup:unmount()
	end, { once = true })

	popup:on({ event.BufWinLeave }, function()
		vim.schedule(function()
			popup:unmount()
		end)
	end, { once = true })

	popup:map("n", { "q", "<esc>" }, function()
		popup:unmount()
	end, { remap = false, nowait = true })

	return popup
end

---@param renderer Renderer
local function get_popup(renderer)
	---@type NuiPopup
	local popup = renderer.popup
	if popup and popup.bufnr and vim.api.nvim_buf_is_valid(popup.bufnr) then
		return popup
	end

	renderer.popup = setup({
		border = {
			text = { top = " Messages " },
		},
	})
	return renderer.popup
end

---@param renderer Renderer
return function(renderer)
	renderer:render_buf(get_popup(renderer).bufnr)
end
