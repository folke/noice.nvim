local require = require("noice.util.lazy")

local Scrollbar = require("noice.view.scrollbar")
local Util = require("noice.util")
local View = require("noice.view")

local uv = vim.uv or vim.loop

---@class NuiView: NoiceView
---@field _nui? NuiPopup|NuiSplit
---@field _loading? boolean
---@field super NoiceView
---@field _hider fun()
---@field _timeout_timer uv_timer_t
---@field _scroll NoiceScrollbar
---@diagnostic disable-next-line: undefined-field
local NuiView = View:extend("NuiView")

function NuiView:init(opts)
  NuiView.super.init(self, opts)
  self._timer = uv.new_timer()
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
      filetype = "noice",
    },
    win_options = {
      wrap = false,
      foldenable = false,
      scrolloff = 0,
      sidescrolloff = 0,
    },
  }, self._opts, self:get_layout())

  local title = {} ---@type string[]
  for _, m in ipairs(self._messages) do
    if m.title then
      title[#title + 1] = m.title
    end
  end

  self._opts = Util.nui.normalize(self._opts)
  if #title > 0 then
    self._opts.border = self._opts.border or {}
    self._opts.border.text = self._opts.border.text or {}
    self._opts.border.text.top = table.concat(title, " | ")
  end
  if self._opts.anchor == "auto" then
    if self._opts.type == "popup" and self._opts.size then
      self._opts = Util.nui.anchorAndResizePopup(self._opts --[[@as NuiPopupOptions]])
    end
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

  self:mount()
  self:update_layout()
  if self._opts.scrollbar ~= false then
    self._scroll = Scrollbar({
      winnr = self._nui.winid,
      padding = Util.nui.normalize_padding(self._opts.border),
    })
    self._scroll:mount()
  end
  self._loading = false
end

function NuiView:mount()
  self._nui:mount()
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
      if not pcall(self.update_layout, self) then
        self._nui:unmount()
        self._nui = nil
        self._visible = false
      end
    end
  end
end

-- Destroys any create windows and buffers with vim.schedule
-- This is needed to properly re-create views in case of E565 errors
function NuiView:destroy()
  local nui = self._nui
  local scroll = self._scroll
  vim.schedule(function()
    if nui then
      nui._.loading = false
      nui._.mounted = true
      nui:unmount()
    end
    if scroll then
      scroll:hide()
    end
  end)
  self._nui = nil
  self._scroll = nil
  self._loading = false
end

function NuiView:hide()
  self._timer:stop()
  if self._nui then
    self._visible = false

    Util.protect(function()
      if self._nui and not self._visible then
        self:clear()
        self._nui:unmount()
        if self._scroll then
          self._scroll:hide()
        end
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
      local hl = vim.split(winhl, ",")
      hl[#hl + 1] = "Search:"
      hl[#hl + 1] = "IncSearch:"
      winhl = table.concat(hl, ",")
      vim.api.nvim_win_set_option(self._nui.border.winid, "winhighlight", winhl)
    end
  end
end

function NuiView:update_layout()
  self._nui:update_layout(self:get_layout())
end

function NuiView:is_mounted()
  if self._nui and self._nui.bufnr and not vim.api.nvim_buf_is_valid(self._nui.bufnr) then
    self._nui.bufnr = nil
  end

  if self._nui and self._nui.winid and not vim.api.nvim_win_is_valid(self._nui.winid) then
    self._nui.winid = nil
  end

  if
    self._nui
    and self._nui.border
    and self._nui.border.winid
    and not vim.api.nvim_win_is_valid(self._nui.border.winid)
  then
    self._nui.border.winid = nil
  end

  if self._nui and self._nui._.mounted and not self._nui.bufnr then
    self._nui._.mounted = false
  end

  return self._nui and self._nui._.mounted and self._nui.bufnr
end

function NuiView:show()
  if self._loading then
    return
  end

  if not self._nui then
    self:create()
  end

  if not self:is_mounted() then
    self:mount()
  end

  vim.bo[self._nui.bufnr].modifiable = true
  self:render(self._nui.bufnr)
  vim.bo[self._nui.bufnr].modifiable = false

  self._nui:show()
  if not self._nui.winid then
    return
  end
  self:tag()
  if not self._visible then
    self:set_win_options(self._nui.winid)
    self:update_layout()
  end

  if self._scroll then
    if self._scroll.winnr ~= self._nui.winid then
      self._scroll:unmount()
      self._scroll.winnr = self._nui.winid
      self._scroll:mount()
    end
    self._scroll:update()
  end
  self:fix_border()
  self:autohide()
end

return NuiView
