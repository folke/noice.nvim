local require = require("noice.util.lazy")

local Config = require("noice.config")
local Util = require("noice.util")

---@class CallOptions
---@field catch? fun(err:string)
---@field finally? fun()
---@field msg? string
---@field retry_on_vim_errors? boolean
---@field retry_on_E11? boolean Retry on errors due to illegal operations while the cmdline window is open
local defaults = {
  retry_on_vim_errors = true,
  retry_on_E11 = false,
  ignore_E565 = true,
  retry_on_E565 = false,
  ignore_keyboard_interrupt = true,
}

---@class Call
---@field _fn fun()
---@field _opts CallOptions
---@field _retry boolean
---@field _defer_retry boolean
local M = {}
M.__index = M

M._errors = 0
M._max_errors = 20

function M.reset()
  M.reset = Util.debounce(200, function()
    M._errors = 0
  end)
  M.reset()
end

---@generic F: fun()
---@param fn F
---@param opts? CallOptions
---@return F
function M.protect(fn, opts)
  if not fn then
    local trace = debug.traceback()
    Util.panic("nil passed to noice.util.call.protect. This should not happen.\n%s", trace)
  end
  local self = setmetatable({}, M)
  self._opts = vim.tbl_deep_extend("force", defaults, opts or {})
  self._fn = fn
  self._retry = false
  return function(...)
    return self(...)
  end
end

function M:on_error(err)
  M._errors = M._errors + 1
  if M._errors > M._max_errors then
    Util.panic("Too many errors. Disabling Noice")
  end
  M.reset()

  if self._opts.catch then
    pcall(self._opts.catch, err)
  end

  if err then
    if self._opts.ignore_keyboard_interrupt and err:lower():find("keyboard interrupt") then
      M._errors = M._errors - 1
      return
    end

    if self._opts.retry_on_E565 and err:find("E565") then
      M._errors = M._errors - 1
      self._defer_retry = true
      return
    end

    if self._opts.ignore_E565 and err:find("E565") then
      M._errors = M._errors - 1
      return
    end

    -- catch any Vim Errors and retry once
    if not self._retry and err:find("Vim:E%d+") and self._opts.retry_on_vim_errors then
      self._retry = true
      return
    end

    if self._opts.retry_on_E11 and err:find("E11:") then
      M._errors = M._errors - 1
      self._defer_retry = true
      return
    end
  end

  pcall(M.log, self, err)
  self:notify(err)
end

function M:log(data)
  local file = Config.options.log
  local fd = io.open(file, "a+")
  if not fd then
    error(("Could not open file %s for writing"):format(file))
  end
  fd:write("\n\n" .. os.date() .. "\n" .. self:format(data, true))
  fd:close()
end

function M:format(err, stack)
  local lines = {}
  table.insert(lines, self._opts.msg or err)

  if stack then
    if self._opts.msg then
      table.insert(lines, err)
    end
    table.insert(lines, debug.traceback("", 5))
  end

  return table.concat(lines, "\n")
end

function M:notify(err)
  local msg = self:format(err, Config.options.debug)
  vim.schedule(function()
    if not pcall(Util.error, msg) then
      vim.notify(msg, vim.log.levels.ERROR, { title = "noice.nvim" })
    end
  end)
end

function M:__call(...)
  local args = vim.F.pack_len(...)

  -- wrap the function and call with args
  local wrapped = function()
    return self._fn(vim.F.unpack_len(args))
  end

  -- error handler
  local error_handler = function(err)
    pcall(self.on_error, self, err)
    return err
  end

  ---@type boolean, any
  local ok, result = xpcall(wrapped, error_handler)
  if self._retry then
    ---@type boolean, any
    ok, result = xpcall(wrapped, error_handler)
  end

  if self._opts.finally then
    pcall(self._opts.finally)
  end

  if not ok and self._defer_retry then
    vim.defer_fn(function()
      self(vim.F.unpack_len(args))
    end, 100)
  end

  return ok and result or nil
end

return M
