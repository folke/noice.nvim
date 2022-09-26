local M = {}

setmetatable(M, {
  __index = function(_, key)
    return require("noice.render." .. key)
  end,
})

return M
