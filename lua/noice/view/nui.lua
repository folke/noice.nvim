local require = require("noice.util.lazy")

local View = require("noice.view")
local Event = require("nui.utils.autocmd").event
local Util = require("noice.util")

---@class NuiRelative
---@field type "'cursor'"|"'editor'"|"'win'"
---@field winid? number
---@field position? { row: number, col: number }

---@alias NuiBorderStyle "'double'"|"'none'"|"'rounded'"|"'shadow'"|"'single'"|"'solid'"

---@class NuiBorder
---@field padding? number[]|{top:number, right:number, bottom:number, left:number}
---@field style? NuiBorderStyle
---@field text? { top: string|boolean, bottom: string|boolean }

---@class NuiBaseOptions
---@field type "split"|"popup"
---@field relative "'cursor'"|"'editor'"|"'win'"|NuiRelative
---@field enter boolean
---@field buf_options? table<string, any>
---@field win_options? table<string, any>
---@field close? {events?:string[], keys?:string[]}

---@class NuiPopupOptions: NuiBaseOptions
---@field position number|string|{ row: number|string, col: number|string}
---@field size number|string|{ row: number|string, col: number|string}
---@field border? NuiBorder|NuiBorderStyle
---@field focusable boolean
---@field zindex? number

---@class NuiSplitOptions: NuiBaseOptions
---@field position "top"|"right"|"bottom"|"left"
---@field size number|string
---@field min_size number
---@field max_size number

---@alias NoiceNuiOptions NuiSplitOptions|NuiPopupOptions

---@class NuiView: NoiceView
---@field _nui? NuiPopup|NuiSplit
---@field super NoiceView
---@field _layout {position: any, size: any}
---@diagnostic disable-next-line: undefined-field
local NuiView = View:extend("NuiView")

function NuiView:create()
  self._layout = self:get_layout()

  ---@type NoiceNuiOptions
  local opts = vim.tbl_deep_extend("force", {}, {
    buf_options = { buftype = "nofile" },
  }, self._opts, self._layout)
  opts = vim.deepcopy(opts)

  Util.nui.fix(opts)

  self._nui = self._opts.type == "split" and require("nui.split")(opts) or require("nui.popup")(opts)

  self._nui:on(Event.VimResized, function()
    self:layout({ force = true })
  end)

  self._nui:on({ Event.BufWinLeave }, function()
    vim.schedule(function()
      self._visible = false
      if self._nui then
        self._nui:unmount()
        self._nui = nil
      end
    end)
  end, { once = false })

  if self._opts.close and self._opts.close.events then
    self._nui:on(self._opts.close.events, function()
      self:hide()
    end, { once = false })
  end

  if self._opts.close and self._opts.close.keys then
    self._nui:map("n", self._opts.close.keys, function()
      self:hide()
    end, { remap = false, nowait = true })
  end

  self._nui:mount()
  self:layout({ force = true })
end

function NuiView:reset()
  if self._nui then
    self._nui:unmount()
    self._nui = nil
    self._visible = false
  end
end

function NuiView:hide()
  if self._nui then
    self._visible = false

    Util.protect(function()
      if self._nui and not self._visible then
        self._nui:hide()
      end
    end, {
      finally = function()
        if self._nui then
          self._nui._.loading = false
        end
      end,
      retry_on_E11 = true,
    })()
  end
end

---@param opts? { force: boolean }
function NuiView:layout(opts)
  opts = opts or {}
  local layout = self:get_layout()
  if opts.force or not vim.deep_equal(layout, self._layout) then
    self._nui:update_layout(self:get_layout())
  end
end

function NuiView:get_layout()
  return Util.nui.get_layout({ width = self:width(), height = self:height() }, self._opts)
end

function NuiView:show()
  if not self._nui then
    self:create()
  end

  self._nui:show()

  self:render(self._nui.bufnr)
  self:layout({ force = not self._visible })
end

return NuiView
