local require = require("noice.util.lazy")

local Hacks = require("noice.util.hacks")
local Config = require("noice.config")

local M = {}

M.stats = require("noice.util.stats")
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

function M.open(uri)
  local cmd
  if vim.fn.has("win32") == 1 then
    cmd = { "cmd.exe", "/c", "start", '""', vim.fn.shellescape(uri) }
  elseif vim.fn.has("macunix") == 1 then
    cmd = { "open", uri }
  else
    cmd = { "xdg-open", uri }
  end

  local ret = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    local msg = {
      "Failed to open uri",
      ret,
      vim.inspect(cmd),
    }
    vim.notify(table.concat(msg, "\n"), vim.log.levels.ERROR)
  end
end

function M.tag(buf, tag)
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")

  if ft == "" then
    vim.api.nvim_buf_set_option(buf, "filetype", "noice")
  end

  if Config.options.debug and vim.api.nvim_buf_get_name(buf) == "" then
    local path = "noice://" .. buf .. "/" .. tag
    local params = {}
    if ft ~= "" and ft ~= "noice" then
      table.insert(params, "filetype=" .. ft)
    end
    if #params > 0 then
      path = path .. "?" .. table.concat(params, "&")
    end
    vim.api.nvim_buf_set_name(buf, path)
  end
end

---@param win window
---@param options table<string, any>
function M.wo(win, options)
  for k, v in pairs(options) do
    if vim.api.nvim_set_option_value then
      vim.api.nvim_set_option_value(k, v, { scope = "local", win = win })
    else
      vim.wo[win][k] = v
    end
  end
end

function M.debounce(ms, fn)
  local timer = vim.loop.new_timer()
  return function(...)
    local argv = vim.F.pack_len(...)
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule_wrap(fn)(vim.F.unpack_len(argv))
    end)
  end
end

---@generic F: fun()
---@param fn F
---@param ms integer
---@param opts? {enabled?:fun():boolean}
---@return F|Interval
function M.interval(ms, fn, opts)
  opts = opts or {}
  ---@type vim.loop.Timer?
  local timer = nil

  ---@class Interval
  local T = {}

  function T.keep()
    if M.is_exiting() then
      return false
    end
    return opts.enabled == nil or opts.enabled()
  end

  function T.running()
    return timer and not timer:is_closing()
  end

  function T.stop()
    if timer and T.running() then
      timer:stop()
    end
  end

  function T.fn()
    pcall(fn)
    if timer and T.running() and not T.keep() then
      timer:stop()
    elseif T.keep() and not T.running() then
      timer = vim.defer_fn(T.fn, ms)
    end
  end

  function T.__call()
    if not T.running() and T.keep() then
      timer = vim.defer_fn(T.fn, ms)
    end
  end

  return setmetatable(T, T)
end

---@param a table<string, any>
---@param b table<string, any>
---@return string[]
function M.diff_keys(a, b)
  local diff = {}
  for k, _ in pairs(a) do
    if not vim.deep_equal(a[k], b[k]) then
      diff[k] = true
    end
  end
  for k, _ in pairs(b) do
    if not vim.deep_equal(a[k], b[k]) then
      diff[k] = true
    end
  end
  return vim.tbl_keys(diff)
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

  local blocking_mode = false
  for _, m in ipairs({ "ic", "ix", "c", "no", "r%?", "rm" }) do
    if mode.mode:find(m) == 1 then
      blocking_mode = true
    end
  end

  local reason = opts.blocking and mode.blocking and "blocking"
    or opts.mode and blocking_mode and ("mode:" .. mode.mode)
    or opts.input and Hacks.before_input and "input"
    or opts.redraw and Hacks.inside_redraw and "redraw"
    or #require("noice.ui.cmdline").cmdlines > 0 and "cmdline"
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
  if M.module_exists("notify") then
    require("notify").notify(msg:format(...), level, {
      title = "noice.nvim",
      on_open = function(win)
        vim.api.nvim_win_set_option(win, "conceallevel", 3)
        local buf = vim.api.nvim_win_get_buf(win)
        vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
        vim.api.nvim_win_set_option(win, "spell", false)
      end,
    })
  else
    vim.notify(msg:format(...), level, {
      title = "noice.nvim",
    })
  end
end

---@type table<string, boolean>
M._once = {}

---@param msg string
---@param level number
---@param ... any
function M.notify_once(msg, level, ...)
  msg = msg:format(...)
  local once = level .. msg
  if not M._once[once] then
    M.notify(msg, level)
    M._once[once] = true
  end
end

function M.warn_once(msg, ...)
  M.notify_once(msg, vim.log.levels.WARN, ...)
end

function M.error_once(msg, ...)
  M.notify_once(msg, vim.log.levels.ERROR, ...)
end

function M.warn(msg, ...)
  M.notify(msg, vim.log.levels.WARN, ...)
end

function M.error(msg, ...)
  M.notify(msg, vim.log.levels.ERROR, ...)
end

--- Will stop Noice and show error
function M.panic(msg, ...)
  require("noice").disable()
  require("noice.view.backend.notify").dismiss()
  vim.notify(msg:format(...), vim.log.levels.ERROR)
  error("Noice was stopped to prevent further errors", 0)
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
  fd:write(data .. "\n")
  fd:close()
end

---@return string
function M.read_file(file)
  local fd = io.open(file, "r")
  if not fd then
    error(("Could not open file %s for reading"):format(file))
  end
  local data = fd:read("*a")
  fd:close()
  return data
end

function M.is_exiting()
  return vim.v.exiting ~= vim.NIL
end

function M.write_file(file, data)
  local fd = io.open(file, "w+")
  if not fd then
    error(("Could not open file %s for writing"):format(file))
  end
  fd:write(data)
  fd:close()
end

---@generic K
---@generic V
---@param tbl table<K, V>
---@param fn fun(key: K, value: V)
---@param sorter? fun(a:V, b:V): boolean
function M.for_each(tbl, fn, sorter)
  local keys = vim.tbl_keys(tbl)
  table.sort(keys, sorter)
  for _, key in ipairs(keys) do
    fn(key, tbl[key])
  end
end

return M
