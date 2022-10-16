local require = require("noice.util.lazy")

local View = require("noice.view")
local NuiView = require("noice.view.nui")

---@class NoiceMiniOptions
---@field timeout integer
---@field reverse? boolean
local defaults = { timeout = 5000 }

---@class MiniView: NoiceView
---@field active table<number, NoiceMessage>
---@field super NoiceView
---@field view? NuiView
---@field timers table<number, vim.loop.Timer>
---@diagnostic disable-next-line: undefined-field
local MiniView = View:extend("MiniView")

function MiniView:init(opts)
  MiniView.super.init(self, opts)
  self.active = {}
  self.timers = {}
  local view_opts = vim.deepcopy(self._opts)
  view_opts.type = "popup"
  view_opts.format = { "{message}" }
  view_opts.timeout = nil
  self.view = NuiView(view_opts)
end

function MiniView:update_options()
  self._opts = vim.tbl_deep_extend("force", defaults, self._opts)
end

function MiniView:autohide(id)
  if not self.timers[id] then
    self.timers[id] = vim.loop.new_timer()
  end
  self.timers[id]:start(self._opts.timeout, 0, function()
    self.active[id] = nil
    self.timers[id] = nil
    vim.schedule(function()
      self:update()
    end)
  end)
end

function MiniView:show()
  for _, message in ipairs(self._messages) do
    -- we already have debug info,
    -- so make sure we dont regen it in the child view
    message._debug = true
    self.active[message.id] = message
    self:autohide(message.id)
  end
  self:update()
end

function MiniView:update()
  local active = vim.tbl_values(self.active)
  table.sort(
    active,
    ---@param a NoiceMessage
    ---@param b NoiceMessage
    function(a, b)
      local ret = a.id < b.id
      if self._opts.reverse then
        return not ret
      end
      return ret
    end
  )
  self.view:display(active, { dirty = true })
end

function MiniView:hide() end

return MiniView
