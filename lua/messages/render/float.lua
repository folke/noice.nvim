local function setup()
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		focusable = true,
		width = 80,
		height = 20,
		anchor = "NE",
		row = 1,
		col = vim.o.columns,
		style = "minimal",
		border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
	})
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	local function close()
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "<ESC>", close, { buffer = buf, nowait = true })
	vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
	vim.api.nvim_create_autocmd({ "BufDelete", "BufLeave", "BufHidden" }, {
		once = true,
		buffer = buf,
		callback = close,
	})
	return buf, win
end

---@param renderer Renderer
return function(renderer)
	if not (renderer.buf and vim.api.nvim_buf_is_valid(renderer.buf)) then
		renderer.buf = setup()
	end
	renderer:render_buf(renderer.buf)
end
