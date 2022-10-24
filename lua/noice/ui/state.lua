local M = {}

---@type table<string, any>
M.state = {}

function M.set(event, ...)
  local msg = { event, ... }
  M.state[event] = msg
end

function M.clear(event)
  M.state[event] = nil
end

function M.is_equal(event, ...)
  local msg = { event, ... }
  return vim.deep_equal(M.state[event], msg)
end

function M.skip(event, ...)
  if M.is_equal(event, ...) then
    return true
  end
  M.set(event, ...)
end

return M
