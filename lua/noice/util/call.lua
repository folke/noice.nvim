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
}

---@class Call
---@field _fn fun()
---@field _opts CallOptions
---@field _retry boolean
---@field _defer_retry boolean
local M = {}
M.__index = M

---@generic F: fun()
---@param fn F
---@param opts? CallOptions
---@return F
function M.protect(fn, opts)
  local self = setmetatable({}, M)
  self._opts = vim.tbl_deep_extend("force", defaults, opts or {})
  self._fn = fn
  self._retry = false
  return function(...)
    return self(...)
  end
end

function M:on_error(err)
  if self._opts.catch then
    pcall(self._opts.catch, err)
  end

  -- catch any Vim Errors and retry once
  if not self._retry and err:find("Vim:E%d+") and self._opts.retry_on_vim_errors then
    self._retry = true
    return
  end

  if self._opts.retry_on_E11 and err and err:find("E11:") then
    self._defer_retry = true
    return
  end

  self:notify(err)
end

function M:notify(err)
  local lines = {}
  table.insert(lines, self._opts.msg or err)

  if Config.options.debug then
    if self._opts.msg then
      table.insert(lines, err)
    end
    table.insert(lines, debug.traceback("", 3))
  end

  Util.error(table.concat(lines, "\n"))
end

function M:__call(...)
  local args = { ... }

  -- wrap the function and call with args
  local wrapped = function()
    return self._fn(unpack(args))
  end

  -- error handler
  local error_handler = function(err)
    self:on_error(err)
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
      self(unpack(args))
    end, 100)
  end

  return ok and result or nil
end

return M
