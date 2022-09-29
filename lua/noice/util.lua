local Config = require("noice.config")

local M = {}

M.stats = require("noice.stats")

function M.is_blocking()
  local Hacks = require("noice.hacks")
  local mode = vim.api.nvim_get_mode()
  return mode.blocking or mode.mode:find("[cro]") or Hacks.inside_redraw or Hacks.before_input
end

function M.redraw()
  vim.cmd.redraw()
  M.stats.track("redraw")
end

---@generic T: fun()
---@param fn T
---@param opts? { retry_on_vim_errors: boolean, msg: string}
---@return T
function M.protect(fn, opts)
  opts = vim.tbl_deep_extend("force", {
    retry_on_vim_errors = true,
  }, opts or {})

  return function(...)
    local args = { ... }

    -- wrap the function and call with args
    local wrapped = function()
      return fn(unpack(args))
    end

    local retry = false

    -- error handler
    local error_handler = function(err)
      -- catch any Vim Errors and retry once
      if not retry and err:find("Vim:E") and opts.retry_on_vim_errors then
        retry = true
        return
      end

      local lines = {}
      table.insert(lines, opts.msg or err)

      if Config.options.debug then
        if opts.msg then
          table.insert(lines, err)
        end
        table.insert(lines, debug.traceback("", 3))
      end

      M.error(table.concat(lines, "\n"))
      return err
    end

    local ok, result = xpcall(wrapped, error_handler)
    if retry then
      ok, result = xpcall(wrapped, error_handler)
    end
    return ok and result or nil
  end
end

function M.try(fn, ...)
  return M.protect(fn)(...)
end

function M.win_apply_config(win, opts)
  opts = vim.tbl_deep_extend("force", vim.api.nvim_win_get_config(win), opts or {})
  vim.api.nvim_win_set_config(win, opts)
end

---@param msg string
---@param level number
---@param ... any
function M.notify(msg, level, ...)
  vim.notify(msg:format(...), level, {
    title = "noice.nvim",
    on_open = function(win)
      vim.api.nvim_win_set_option(win, "conceallevel", 3)
      local buf = vim.api.nvim_win_get_buf(win)
      vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
      vim.api.nvim_win_set_option(win, "spell", false)
    end,
  })
end

function M.warn(msg, ...)
  M.notify(msg, vim.log.levels.WARN, ...)
end

function M.error(msg, ...)
  M.notify(msg, vim.log.levels.ERROR, ...)
end

function M.info(msg, ...)
  M.notify(msg, vim.log.levels.INFO, ...)
end

return M
