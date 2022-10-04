local require = require("noice.util.lazy")

local Hacks = require("noice.hacks")

local M = {}

M.stats = require("noice.util.stats")
M.cursor = require("noice.util.cursor")
M.call = require("noice.util.call")
M.nui = require("noice.util.nui")

---@generic F: fun()
---@param fn F
---@return F
function M.once(fn)
  local done = false
  return function(...)
    if not done then
      fn(...)
      done = true
    end
  end
end

function M.module_exists(mod)
  return pcall(_G.require, mod) == true
end

function M.diff(a, b)
  a = vim.deepcopy(a)
  b = vim.deepcopy(b)
  M._diff(a, b)
  return { left = a, right = b }
end

function M._diff(a, b)
  if a == b then
    return true
  end
  if type(a) ~= type(b) then
    return false
  end
  if type(a) == "table" then
    local equal = true
    for k, v in pairs(a) do
      if M._diff(v, b[k]) then
        a[k] = nil
        b[k] = nil
      else
        equal = false
      end
    end
    for k, _ in pairs(b) do
      if a[k] == nil then
        equal = false
        break
      end
    end
    return equal
  end
  return false
end

---@param opts? {blocking:boolean, mode:boolean, input:boolean, redraw:boolean}
function M.is_blocking(opts)
  opts = vim.tbl_deep_extend("force", {
    blocking = true,
    mode = true,
    input = true,
    redraw = true,
  }, opts or {})
  local mode = vim.api.nvim_get_mode()
  local reason = opts.blocking and mode.blocking and "blocking"
    or opts.mode and mode.mode:find("[cro]") and "mode"
    or opts.input and Hacks.before_input and "input"
    or opts.redraw and Hacks.inside_redraw and "redraw"
    or nil
  return reason ~= nil, reason
end

function M.redraw()
  vim.cmd.redraw()
  M.stats.track("redraw")
end

M.protect = M.call.protect

function M.try(fn, ...)
  return M.call.protect(fn)(...)
end

function M.win_apply_config(win, opts)
  opts = vim.tbl_deep_extend("force", vim.api.nvim_win_get_config(win), opts or {})
  vim.api.nvim_win_set_config(win, opts)
end

---@param msg string
---@param level number
---@param ... any
function M.notify(msg, level, ...)
  require("noice.view.notify").get().notify(msg:format(...), level, {
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

function M.debug(data)
  local file = "./noice.log"
  local fd = io.open(file, "a+")
  if not fd then
    error(("Could not open file %s for writing"):format(file))
  end
  fd:write("\n" .. data)
  fd:close()
end

return M
