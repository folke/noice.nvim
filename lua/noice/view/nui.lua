local View = require("noice.view")

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

---@alias NoiceNuiOptions NuiSplitOptions|NuiPopupOptions

---@class NuiView: NoiceView
---@field _nui? NuiPopup|NuiSplit
---@field _layout {position: any, size: any}
---@diagnostic disable-next-line: undefined-field
local NuiView = View:extend("NuiView")

function NuiView:create()
  self._layout = self:get_layout()
  local opts = vim.tbl_deep_extend("force", self._opts, self._layout)

  self._nui = self._opts.type == "split" and require("nui.split")(opts) or require("nui.popup")(opts)
  -- TODO: on_resize
  self._nui:on({ "BufWinLeave" }, function()
    vim.schedule(function()
      self:hide()
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
end

function NuiView:hide()
  if self._nui then
    self._nui:hide()
    self._visible = false
  end
end

function NuiView:get_layout()
  local position = vim.deepcopy(self._opts.position)
  local size = vim.deepcopy(self._opts.size)

  if size and self._opts.type == "popup" then
    if size == "auto" then
      size = { height = "auto", width = "auto" }
    end
    if size.width == "auto" then
      size.width = math.max(1, self:width())
    end
    if size.height == "auto" then
      size.height = math.max(1, self:height())
    end
  end

  if size and self._opts.type == "split" then
    if size == "auto" then
      if position == "top" or position == "bottom" then
        size = math.max(1, self:height())
      else
        size = math.max(1, self:width())
      end
    end
  end
  return { size = size, position = position }
end

function NuiView:show()
  if not self._nui then
    self:create()
  end

  self._nui:show()

  self:render(self._nui.bufnr)

  local layout = self:get_layout()
  if not vim.deep_equal(layout, self._layout) then
    self._nui:update_layout(self:get_layout())
  end
end

return NuiView
