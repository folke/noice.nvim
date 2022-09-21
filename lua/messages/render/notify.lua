---@param renderer Renderer
return function(renderer)
	local text = renderer:get_text()
	local level = renderer.opts.level or "info"

	renderer.notif = require("notify")(text, level, {
		title = renderer.opts.title or "Foo",
		replace = renderer.opts.replace ~= false and renderer.notif or nil,
		on_open = function(win)
			renderer.win = win
		end,
		on_close = function()
			renderer.notif = nil
			renderer.win = nil
		end,
		render = function(buf, notif, hl, config)
			require("notify.render")["default"](buf, notif, hl, config)
			local win = vim.fn.bufwinid(buf)
			if win ~= -1 then
				local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				local width = config.minimum_width()
				for _, line in pairs(buf_lines) do
					width = math.max(width, vim.str_utfindex(line))
				end
				local height = #buf_lines
				height = math.min(config.max_height() or 1000, height)
				width = math.min(config.max_width() or 1000, width)
				local opts = vim.api.nvim_win_get_config(win)
				opts.width = width
				opts.height = height
				vim.api.nvim_win_set_config(win, opts)
			end
			renderer:render_buf(buf, { highlights_only = false, offset = 2 })
			vim.cmd([[redraw]])
		end,
	})
end
