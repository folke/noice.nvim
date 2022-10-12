local require = require("noice.util.lazy")

local View = require("noice.view")
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
---@field timeout? number
---@field min_size number
---@field max_size number

---@alias NoiceNuiOptions NuiSplitOptions|NuiPopupOptions

---@class NuiView: NoiceView
---@field _nui? NuiPopup|NuiSplit
---@field super NoiceView
---@field _hider fun()
---@filed _timeout_timer Timer
---@diagnostic disable-next-line: undefined-field
local NuiView = View:extend("NuiView")

function NuiView:init(opts)
  NuiView.super.init(self, opts)
  self._timer = vim.loop.new_timer()
end

function NuiView:autohide()
  if self._opts.timeout then
    self._timer:start(self._opts.timeout, 0, function()
      if self._visible then
        vim.schedule(function()
          self:hide()
        end)
      end
      self._timer:stop()
    end)
  end
end

function NuiView:update_options()
  self._opts = vim.tbl_deep_extend("force", {}, {
    buf_options = {
      buftype = "nofile",
    },
    win_options = {
      foldenable = false,
    },
  }, self._opts, self:get_layout())

  Util.nui.fix(self._opts)
end

function NuiView:create()
  -- needed, since Nui mutates the options
  local opts = vim.deepcopy(self._opts)
  self._nui = self._opts.type == "split" and require("nui.split")(opts) or require("nui.popup")(opts)

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

  -- NOTE: this is needed, to make sure the border is rendered properly during blocking events
  self._nui:update_layout(self:get_layout())
end

---@param old NoiceNuiOptions
---@param new NoiceNuiOptions
function NuiView:reset(old, new)
  self._timer:stop()
  if self._nui then
    local layout = false
    local diff = vim.tbl_filter(function(key)
      if vim.tbl_contains({ "relative", "size", "position" }, key) then
        layout = true
        return false
      end
      if key == "timeout" then
        return false
      end
      return true
    end, Util.diff_keys(old, new))

    if #diff > 0 then
      self._nui:unmount()
      self._nui = nil
      self._visible = false
    elseif layout then
      self._nui:update_layout(self:get_layout())
    end
  end
end

function NuiView:hide()
  self._timer:stop()
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

function NuiView:get_layout()
  return Util.nui.get_layout({ width = self:width(), height = self:height() }, self._opts)
end

function NuiView:tag()
  Util.tag(self._nui.bufnr, "nui." .. self._opts.type)
  if self._nui.border and self._nui.border.bufnr then
    Util.tag(self._nui.border.bufnr, "nui." .. self._opts.type .. ".border")
  end
end

function NuiView:show()
  if not self._nui then
    self:create()
  end

  if not self._nui._.mounted then
    self._nui:mount()
  end

  self._nui:show()
  if not self._visible then
    self._nui:update_layout(self:get_layout())
  end

  self:tag()

  self:render(self._nui.bufnr)
  self:autohide()
end

return NuiView
