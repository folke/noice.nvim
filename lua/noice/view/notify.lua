local require = require("noice.util.lazy")

local Util = require("noice.util")
local View = require("noice.view")

local M = {}

function M.max_height()
  return math.floor(vim.o.lines * 0.75)
end

function M.max_width()
  return math.floor(vim.o.columns * 0.75)
end

---@alias notify.RenderFun fun(buf:buffer, notif: Notification, hl: NotifyBufHighlights, config: notify.Config)

---@param config notify.Config
---@return notify.RenderFun
function M.get_render(config)
  local ret = config.render()
  if type(ret) == "string" then
    ret = require("notify.render")[ret]
  end
  return ret
end

---@class NotifyView: NoiceView
---@field win? number
---@field buf? number
---@field notif? notify.Record|{instant: boolean}
---@diagnostic disable-next-line: undefined-field
local NotifyView = View:extend("NotifyView")

function NotifyView.get()
  if Util.is_blocking() then
    if not M._instant_notify then
      M._instant_notify = require("notify").instance({
        stages = "static",
      }, true)
    end
    return M._instant_notify
  end
  return require("notify")
end

function NotifyView:notify_render()
  return function(buf, notif, hl, config)
    -- run notify view
    M.get_render(config)(buf, notif, hl, config)

    ---@type string[]
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local offset = #buf_lines - self:height() + 1

    -- do our rendering
    self:render(buf, { offset = offset, highlight = true })

    -- resize notification
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
      ---@type number
      local width = config.minimum_width()
      for _, line in pairs(buf_lines) do
        width = math.max(width, vim.str_utfindex(line))
      end
      width = math.min(M.max_width() or 1000, width)
      local height = math.min(M.max_height() or 1000, #buf_lines)
      Util.win_apply_config(win, { width = width, height = height })
    end
  end
end

function NotifyView:show()
  -- TODO: add options
  -- TODO: add option to enable/disable highlights of the message
  local text = self:content()
  local level = self._opts.level or "info"
  local instant = Util.is_blocking()

  local replace = self._opts.replace ~= false and self.notif or nil
  if replace and replace.instant ~= instant then
    replace = nil
  end

  local opts = {
    title = self._opts.title or "Noice",
    replace = replace,
    keep = function()
      return Util.is_blocking()
    end,
    on_open = function(win)
      self.win = win
    end,
    on_close = function()
      self.notif = nil
      self.win = nil
    end,
    render = Util.protect(self:notify_render()),
  }

  self.notif = NotifyView.get().notify(text, level, opts)
  self.notif.instant = instant
end

function NotifyView:hide()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
    self.win = nil
  end
end

return NotifyView
