local Util = require("noice.util")

local M = {}

function M.max_height()
  return math.floor(vim.o.lines * 0.75)
end

function M.max_width()
  return math.floor(vim.o.columns * 0.75)
end

---@param message string | string[]: Notification message
---@param level string | number: Log level. See vim.log.levels
---@param opts notify.Options: Notification options
---@return notify.Record
function M.notify(message, level, opts)
  return require("notify").notify(message, level, opts)
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

---@param renderer Renderer
---@return notify.RenderFun
function M.render(renderer)
  return function(buf, notif, hl, config)
    -- run notify renderer
    M.get_render(config)(buf, notif, hl, config)

    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local offset = #buf_lines - #renderer.lines

    -- do our rendering
    renderer:render_buf(buf, { highlights_only = true, offset = offset })

    -- resize notification
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
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

---@param renderer Renderer
return function(renderer)
  if not renderer.visible then
    if M.renderer.win and vim.api.nvim_win_is_valid(M.renderer.win) then
      vim.api.nvim_win_close(M.renderer.win, true)
      M.renderer.win = nil
    end
    return M.hide_last()
  end

  local text = renderer:get_text()
  local level = renderer.opts.level or "info"
  local render = M.render(renderer)
  render = Util.protect(render)

  renderer.notif = M.notify(text, level, {
    title = renderer.opts.title or "Noice",
    replace = renderer.opts.replace ~= false and renderer.notif or nil,
    on_open = function(win)
      renderer.win = win
    end,
    on_close = function()
      renderer.notif = nil
      renderer.win = nil
    end,
    render = render,
  })
end
