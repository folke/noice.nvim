local require = require("noice.util.lazy")

local View = require("noice.view")
local Filter = require("noice.message.filter")
local NuiView = require("noice.view.nui")

---@class NoiceMiniOptions
---@field timeout integer
local defaults = { timeout = 5000 }

---@class MiniView: NoiceView
---@field active NoiceMessage[]
---@field super NoiceView
---@field view? NuiView
---@diagnostic disable-next-line: undefined-field
local MiniView = View:extend("NotifyView")

function MiniView:init(opts)
  MiniView.super.init(self, opts)
  self.active = {}
  local view_opts = vim.deepcopy(self._opts)
  view_opts.type = "popup"
  view_opts.format = { "{message}" }
  view_opts.timeout = nil
  self.view = NuiView(view_opts)
end

function MiniView:update_options()
  self._opts = vim.tbl_deep_extend("force", defaults, self._opts)
end

function MiniView:show()
  for _, message in ipairs(self._messages) do
    if #Filter.filter(self.active, { message = message }) == 0 then
      table.insert(self.active, 1, message)
      vim.defer_fn(function()
        self.active = Filter.filter(self.active, { ["not"] = { message = message } })
        self.view:display(self.active, { dirty = true, format = true })
      end, self._opts.timeout)
    end
  end
  self.view:display(self.active, { dirty = true, format = true })
end

return MiniView
