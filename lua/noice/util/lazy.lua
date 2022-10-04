return function(module)
  -- if already loaded, return the module
  -- otherwise return a lazy module
  return type(package.loaded[module]) == "table" and package.loaded[module]
    or setmetatable({}, {
      __index = function(_, key)
        return require(module)[key]
      end,
      __newindex = function(_, key, value)
        require(module)[key] = value
      end,
      __call = function(_, ...)
        return require(module)(...)
      end,
    })
end
