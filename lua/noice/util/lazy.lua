return function(module)
  local mod = nil

  local function load()
    if not mod then
      mod = require(module)
      package.loaded[module] = mod
    end
    return mod
  end
  -- if already loaded, return the module
  -- otherwise return a lazy module
  return type(package.loaded[module]) == "table" and package.loaded[module]
    or setmetatable({}, {
      __index = function(_, key)
        return load()[key]
      end,
      __newindex = function(_, key, value)
        load()[key] = value
      end,
      __call = function(_, ...)
        return load()(...)
      end,
    })
end
