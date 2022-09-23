local M = {}

M.nop = function() end

setmetatable(M, {
  __index = function(_, key)
    return require("noice.render." .. key)
  end,
})

return M
