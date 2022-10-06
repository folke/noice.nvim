local require = require("noice.util.lazy")

local Util = require("noice.util")
local View = require("noice.view")

---@class NoiceNotifyOptions
---@field title string
---@field level string|number
---@field merge boolean Merge messages into one Notification or create separate notifications
---@field replace boolean Replace existing notification or create a new one
---@field highlight boolean Highlight message, or render as plain text
local defaults = {
  title = "Notification",
  merge = true,
  level = vim.log.levels.INFO,
  replace = true,
  highlight = true,
}

---@class NotifyInstance
---@field notify fun(msg:string, level:string|number, opts?:table): notify.Record}

---@alias notify.RenderFun fun(buf:buffer, notif: Notification, hl: NotifyBufHighlights, config: notify.Config)

---@class NotifyView: NoiceView
---@field win? number
---@field buf? number
---@field notif table<NotifyInstance, notify.Record>
---@field super NoiceView
---@diagnostic disable-next-line: undefined-field
local NotifyView = View:extend("NotifyView")

---@return NotifyInstance
function NotifyView.instance()
  if Util.is_blocking() then
    if not NotifyView._instant_notify then
      NotifyView._instant_notify = require("notify").instance({
        stages = "static",
      }, true)
    end
    return NotifyView._instant_notify
  end
  return require("notify")
end

function NotifyView.dismiss()
  require("notify").dismiss({ pending = true, silent = true })
  if NotifyView._instant_notify then
    NotifyView._instant_notify.dismiss({ pending = true, silent = true })
  end
end

function NotifyView:init(opts)
  NotifyView.super.init(self, opts)
  self.notif = {}
end

function NotifyView:update_options()
  self._opts = vim.tbl_deep_extend("force", defaults, self._opts)
end

---@param config notify.Config
---@return notify.RenderFun
function NotifyView:get_render(config)
  ---@type string|notify.RenderFun
  local ret = config.render()
  if type(ret) == "string" then
    ---@type notify.RenderFun
    ret = require("notify.render")[ret]
  end
  return ret
end

---@param messages NoiceMessage[]
function NotifyView:notify_render(messages)
  ---@param config notify.Config
  return function(buf, notif, hl, config)
    -- run notify view
    self:get_render(config)(buf, notif, hl, config)

    ---@type string[]
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local offset = #buf_lines - self:height(messages) + 1

    -- do our rendering
    if self._opts.highlight then
      self:render(buf, { offset = offset, highlight = true, messages = messages })
    end

    -- resize notification
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
      ---@type number
      local width = config.minimum_width()
      for _, line in pairs(buf_lines) do
        width = math.max(width, vim.str_utfindex(line))
      end
      width = math.min(config.max_width() or 1000, width)
      local height = math.min(config.max_height() or 1000, #buf_lines)
      Util.win_apply_config(win, { width = width, height = height })
    end
  end
end

---@alias NotifyMsg {content:string, messages:NoiceMessage[], title?:string, level?:string}

---@param msg NotifyMsg
function NotifyView:_notify(msg)
  local level = msg.level or self._opts.level

  local instance = NotifyView.instance()

  local opts = {
    title = msg.title or self._opts.title,
    replace = self._opts.replace and self.notif[instance],
    keep = function()
      return Util.is_blocking()
    end,
    on_open = function(win)
      vim.api.nvim_win_set_option(win, "foldenable", false)
      if self._opts.merge then
        self.win = win
      end
    end,
    on_close = function()
      self.notif[instance] = nil
      self.win = nil
    end,
    render = Util.protect(self:notify_render(msg.messages)),
  }

  self.notif[instance] = instance.notify(msg.content, level, opts)
end

function NotifyView:show()
  -- TODO: add documentation

  ---@type NotifyMsg[]
  local todo = {}

  if self._opts.merge then
    table.insert(todo, {
      content = self:content(),
      messages = self._messages,
    })
  else
    for _, m in ipairs(self._messages) do
      table.insert(todo, {
        content = m:content(),
        messages = { m },
        title = m.opts.title,
        level = m.level,
      })
    end
  end

  for _, msg in ipairs(todo) do
    self:_notify(msg)
  end
end

function NotifyView:hide()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
    self.win = nil
  end
end

return NotifyView
