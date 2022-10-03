local require = require("noice.util.lazy")

local Msg = require("noice.ui.msg")

local M = {}

---@type table<string, NoiceFilter>
M.defaults = {
  ruler = { event = Msg.events.ruler },
  message = { event = Msg.events.show },
  command = { event = Msg.events.showcmd },
  mode = { event = Msg.events.showmode },
  search = { event = Msg.events.show, kind = Msg.kinds.search_count },
}

return M
