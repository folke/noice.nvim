local require = require("noice.util.lazy")

local Manager = require("noice.manager")
local Config = require("noice.config")

---@param filter NoiceFilter
---@return NoiceStatus
local function NoiceStatus(filter)
  local function _get()
    return Manager.get(filter, {
      count = 1,
      sort = true,
    })[1]
  end
  ---@class NoiceStatus
  return {
    has = function()
      return _get() ~= nil
    end,
    get = function()
      local message = _get()
      if message then
        return vim.trim(message:content())
      end
    end,
    get_hl = function()
      local message = _get()
      message:_update()
      if message and message._lines[1] then
        local ret = ""
        local line = message._lines[#message._lines]
        for _, text in ipairs(line._texts) do
          if text.extmark and text.extmark.hl_group then
            -- use hl_group
            ret = ret .. "%#" .. text.extmark.hl_group .. "#" .. text:content()
          else
            -- or reset to StatusLine
            ret = ret .. "%#StatusLine#" .. text:content()
          end
        end
        return ret
      end
    end,
  }
end

local empty_status = NoiceStatus({ event = "__will_never_match__" })

---@type table<string, NoiceStatus>
local status = {}

return setmetatable(status, {
  __index = function(_, key)
    if Config.options.status and Config.options.status[key] then
      status[key] = NoiceStatus(Config.options.status[key])
      return status[key]
    else
      -- can happen when Noice is not loaded yet. Return an empty status
      return empty_status
    end
  end,
})
