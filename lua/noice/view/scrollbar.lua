local require = require("noice.util.lazy")

local Object = require("nui.object")
local Util = require("noice.util")

---@class NoiceScrollbar
---@field winnr integer
---@field ns_id integer
---@field autocmd_id integer
---@field bar {bufnr:integer, winnr:integer}?
---@field thumb {bufnr:integer, winnr:integer}?
---@field visible boolean
---@field opts ScrollbarOptions
---@overload fun(opts?:ScrollbarOptions):NoiceScrollbar
local Scrollbar = Object("NuiScrollbar")

---@class ScrollbarOptions
local defaults = {
  winnr = 0,
  autohide = true,
  hl_group = {
    bar = "NoiceScrollbar",
    thumb = "NoiceScrollbarThumb",
  },
  ---@type _.NuiBorderPadding
  padding = {
    top = 0,
    right = 0,
    bottom = 0,
    left = 0,
  },
}

---@param opts? ScrollbarOptions
function Scrollbar:init(opts)
  self.opts = vim.tbl_deep_extend("force", defaults, opts or {})
  self.winnr = self.opts.winnr == 0 and vim.api.nvim_get_current_win() or self.opts.winnr
  self.visible = false
end

function Scrollbar:mount()
  self.autocmd_id = vim.api.nvim_create_autocmd({ "WinScrolled", "CursorMoved" }, {
    callback = function()
      self:update()
    end,
  })
  self:update()
end

function Scrollbar:unmount()
  if self.autocmd_id then
    vim.api.nvim_del_autocmd(self.autocmd_id)
    self.autocmd_id = nil
  end
  self:hide()
end

function Scrollbar:show()
  if not self.visible then
    self.visible = true
    self.bar = self:_open_win({ normal = self.opts.hl_group.bar })
    self.thumb = self:_open_win({ normal = self.opts.hl_group.thumb })
  end
  self:update()
end

function Scrollbar:hide()
  if self.visible then
    self.visible = false
    local bar = self.bar
    if bar then
      pcall(vim.api.nvim_buf_delete, bar.bufnr, { force = true })
      pcall(vim.api.nvim_win_close, bar.winnr, true)
      self.bar = nil
    end

    local thumb = self.thumb
    if thumb then
      pcall(vim.api.nvim_buf_delete, thumb.bufnr, { force = true })
      pcall(vim.api.nvim_win_close, thumb.winnr, true)
      self.thumb = nil
    end
  end
end

function Scrollbar:update()
  if not vim.api.nvim_win_is_valid(self.winnr) then
    return self:hide()
  end

  local pos = vim.api.nvim_win_get_position(self.winnr)

  local dim = {
    row = pos[1] - self.opts.padding.top,
    col = pos[2] - self.opts.padding.left,
    width = vim.api.nvim_win_get_width(self.winnr) + self.opts.padding.left + self.opts.padding.right,
    height = vim.api.nvim_win_get_height(self.winnr) + self.opts.padding.top + self.opts.padding.bottom,
  }

  local buf_height = Util.nui.win_buf_height(self.winnr)

  if self.opts.autohide and dim.height >= buf_height then
    self:hide()
    return
  elseif not self.visible then
    self:show()
  end

  if not (vim.api.nvim_win_is_valid(self.bar.winnr) and vim.api.nvim_win_is_valid(self.thumb.winnr)) then
    self:hide()
    self:show()
  end

  local zindex = vim.api.nvim_win_get_config(self.winnr).zindex or 50

  Util.win_apply_config(self.bar.winnr, {
    height = dim.height,
    width = 1,
    col = dim.col + dim.width - 1,
    row = dim.row,
    zindex = zindex + 1,
  })

  local thumb_height = math.floor(dim.height * dim.height / buf_height + 0.5)
  thumb_height = math.max(1, thumb_height)

  local pct = vim.api.nvim_win_get_cursor(self.winnr)[1] / buf_height

  local thumb_offset = math.floor(pct * (dim.height - thumb_height) + 0.5)

  Util.win_apply_config(self.thumb.winnr, {
    width = 1,
    height = thumb_height,
    row = dim.row + thumb_offset,
    col = dim.col + dim.width - 1, -- info.col was already added scrollbar offset.
    zindex = zindex + 2,
  })
end

function Scrollbar:_open_win(opts)
  local bufnr = vim.api.nvim_create_buf(false, true)
  Util.tag(bufnr, "scrollbar")
  local ret = {
    bufnr = bufnr,
    winnr = vim.api.nvim_open_win(bufnr, false, {
      relative = "editor",
      focusable = false,
      width = 1,
      -- HACK: height should be >=2 in case of winbar, which is inherited from the parent window
      -- Change back to 1 when the upstream issue is fixed.
      -- See https://github.com/neovim/neovim/issues/19464
      height = 2,
      row = 0,
      col = 0,
      style = "minimal",
      noautocmd = true,
    }),
  }
  vim.api.nvim_win_set_option(ret.winnr, "winhighlight", "Normal:" .. opts.normal)
  return ret
end

return Scrollbar
