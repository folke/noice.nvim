local Manager = require("noice.manager")
local Msg = require("noice.ui.msg")

local M = {}

---@param filter NoiceFilter
local function NoiceStatus(filter)
  local function _get()
    return Manager.get(filter, {
      count = 1,
      sort = true,
    })[1]
  end
  ---@type NoiceMessage?
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

M.ruler = NoiceStatus({ event = Msg.events.ruler })
M.message = NoiceStatus({ event = Msg.events.show })
M.command = NoiceStatus({ event = Msg.events.showcmd })
M.mode = NoiceStatus({ event = Msg.events.showmode })
M.search = NoiceStatus({ event = Msg.events.show, kind = Msg.kinds.search_count })

return M
