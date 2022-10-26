local require = require("noice.util.lazy")

local View = require("noice.view")
local Util = require("noice.util")
local Scrollbar = require("noice.view.scrollbar")

---@class NuiView: NoiceView
---@field _nui? NuiPopup|NuiSplit
---@field _loading? boolean
---@field super NoiceView
---@field _hider fun()
---@field _timeout_timer vim.loop.Timer
---@field _scroll NoiceScrollbar
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
      scrolloff = 0,
      sidescrolloff = 0,
    },
  }, self._opts, self:get_layout())

  self._opts = Util.nui.normalize(self._opts)
  if self._opts.anchor == "auto" then
    if self._opts.type == "popup" and self._opts.size then
      local width = self._opts.size.width
      local height = self._opts.size.height
      if type(width) == "number" and type(height) == "number" then
        local col = self._opts.position and self._opts.position.col
        local row = self._opts.position and self._opts.position.row
        self._opts.anchor = Util.nui.anchor(width, height)
        if self._opts.anchor:find("S") and row then
          self._opts.position.row = -row + 1
        end
        if self._opts.anchor:find("E") and col then
          self._opts.position.col = -col
        end
      end
    else
      self._opts.anchor = "NW"
    end
  end
end

-- Check if other floating windows are overlapping and move out of the way
function NuiView:smart_move()
  if not (self._opts.type == "popup" and self._opts.relative and self._opts.relative.type == "editor") then
    return
  end

  local wins = vim.tbl_filter(function(win)
    return win ~= self._nui.winid
      and not (self._nui.border and self._nui.border.winid == win)
      and vim.api.nvim_win_is_valid(win)
      and vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "noice"
      and vim.api.nvim_win_get_config(win).relative == "editor"
      and Util.nui.overlap(self._nui.winid, win)
  end, vim.api.nvim_list_wins())

  if #wins > 0 then
    local layout = self:get_layout()
    layout.position.row = 2
    self._nui:update_layout(layout)
  end
end

function NuiView:create()
  if self._loading then
    return
  end
  self._loading = true
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

  self:update_layout()
  self._scroll = Scrollbar({
    winnr = self._nui.winid,
    border_size = Util.nui.normalize_padding(self._opts.border),
  })
  self._scroll:mount()
  -- NOTE: this is needed, to make sure the border is rendered properly during blocking events
  self._loading = false
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
      self:update_layout()
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
        self._scroll:hide()
      end
    end, {
      finally = function()
        if self._nui then
          self._nui._.loading = false
        end
      end,
      retry_on_E11 = true,
      retry_on_E565 = true,
    })()
  end
end

function NuiView:get_layout()
  local layout = Util.nui.get_layout({ width = self:width(), height = self:height() }, self._opts)
  if self._opts.type == "popup" then
    ---@cast layout _.NuiPopupOptions
    if
      layout.size
      and type(layout.size.width) == "number"
      and layout.size.width < self:width()
      and self._opts.win_options
      and self._opts.win_options.wrap
    then
      local height = 0
      for _, m in ipairs(self._messages) do
        for _, l in ipairs(m._lines) do
          height = height + math.max(1, (math.ceil(l:width() / layout.size.width)))
        end
      end
      layout = Util.nui.get_layout({ width = self:width(), height = height }, self._opts)
    end
  end
  return layout
end

function NuiView:tag()
  Util.tag(self._nui.bufnr, "nui." .. self._opts.type)
  if self._nui.border and self._nui.border.bufnr then
    Util.tag(self._nui.border.bufnr, "nui." .. self._opts.type .. ".border")
  end
end

function NuiView:fix_border()
  if
    self._nui
    and self._nui.border
    and self._nui.border.winid
    and vim.api.nvim_win_is_valid(self._nui.border.winid)
  then
    local winhl = vim.api.nvim_win_get_option(self._nui.border.winid, "winhighlight") or ""
    if not winhl:find("IncSearch") then
      winhl = winhl .. ",Search:,Incsearch:"
      vim.api.nvim_win_set_option(self._nui.border.winid, "winhighlight", winhl)
    end
  end
end

function NuiView:update_layout()
  self._nui:update_layout(self:get_layout())
end

function NuiView:show()
  if self._loading then
    return
  end

  if not self._nui then
    self:create()
  end

  if not self._nui._.mounted then
    self._nui:mount()
  end

  self._nui:show()
  self:set_win_options(self._nui.winid)
  self:tag()
  if not self._visible then
    self:update_layout()
    self:smart_move()
  end

  vim.bo[self._nui.bufnr].modifiable = true
  self:render(self._nui.bufnr)
  vim.bo[self._nui.bufnr].modifiable = false

  self._scroll.winnr = self._nui.winid
  self._scroll:show()
  self:fix_border()
  self:autohide()
end

return NuiView
