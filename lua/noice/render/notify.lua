local Util = require("noice.util")

local M = {}

function M.max_height()
  return math.floor(vim.o.lines * 0.75)
end

function M.max_width()
  return math.floor(vim.o.columns * 0.75)
end

function M.notify()
  return require("notify")
end

function M.instant_notify()
  if not M._instant_notify then
    M._instant_notify = require("notify").instance({
      stages = "static",
    }, true)
  end
  return M._instant_notify
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

---@param view NoiceView
---@return notify.RenderFun
function M.render(view)
  return function(buf, notif, hl, config)
    -- run notify view
    M.get_render(config)(buf, notif, hl, config)

    ---@type string[]
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local offset = #buf_lines - view:height() + 1

    -- do our rendering
    view:highlight(buf, offset)

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

---@param view NoiceView
return function(view)
  if not view.visible then
    if view.win and vim.api.nvim_win_is_valid(view.win) then
      vim.api.nvim_win_close(view.win, true)
      view.win = nil
    end
    return
  end

  local text = view:content()
  local level = view.opts.level or "info"
  local render = Util.protect(M.render(view))
  local instant = require("noice.instant").in_instant()
  local notify = instant and M.instant_notify() or M.notify()

  ---@type notify.Record | {instant: boolean} | nil
  local replace = view.opts.replace ~= false and view.notif or nil
  if replace and replace.instant ~= instant then
    replace = nil
  end

  if instant then
    text = "[instant] " .. text
  end

  local opts = {
    instant = instant,
    title = view.opts.title or "Noice",
    replace = replace,
    keep = function()
      return require("noice.instant").in_instant()
    end,
    on_open = function(win)
      view.win = win
    end,
    on_close = function()
      view.notif = nil
      view.win = nil
    end,
    render = render,
  }

  view.notif = notify.notify(text, level, opts)
  view.notif.instant = instant
end
