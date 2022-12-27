local require = require("noice.util.lazy")

local Util = require("noice.util")
local View = require("noice.view")

---@class NoiceNotifySendOptions
---@field title string
---@field level? string|number Message log level
---@field merge boolean Merge messages into one Notification or create separate notifications
---@field replace boolean Replace existing notification or create a new one
local defaults = {
  title = "Notification",
  merge = false,
  level = nil, -- vim.log.levels.INFO,
  replace = false,
}

---@class NotifySendArgs
---@field title? string
---@field body string
---@field app_name? string
---@field urgency? string
---@field expire_time? integer
---@field icon? string
---@field category? string
---@field hint? string
---@field print_id? boolean
---@field replace_id? string

---@class NotifySendView: NoiceView
---@field win? number
---@field buf? number
---@field notif? string
---@field super NoiceView
---@diagnostic disable-next-line: undefined-field
local NotifySendView = View:extend("NotifySendView")

function NotifySendView:init(opts)
  NotifySendView.super.init(self, opts)
end

function NotifySendView:is_available()
  return vim.fn.executable("notify-send") == 1
end

function NotifySendView:update_options()
  self._opts = vim.tbl_deep_extend("force", defaults, self._opts)
end

---@alias NotifySendMsg {content:string, messages:NoiceMessage[], title?:string, level?:NotifyLevel, opts?: table}

---@param level? NotifyLevel|number
function NotifySendView:get_urgency(level)
  if level then
    local l = type(level) == "number" and level or vim.log.levels[level:lower()] or vim.log.levels.INFO
    if l <= 1 then
      return "low"
    end
    if l >= 4 then
      return "critical"
    end
  end
  return "normal"
end

---@param msg NotifySendMsg
function NotifySendView:_notify(msg)
  local level = self._opts.level or msg.level

  ---@type NotifySendArgs
  local opts = {
    app_name = "nvim",
    icon = "nvim",
    title = msg.title or self._opts.title,
    body = msg.content,
    replace_id = self._opts.replace and self.notif or nil,
    urgency = self:get_urgency(level),
  }

  local args = { "--print-id" }
  for k, v in pairs(opts) do
    if not (k == "title" or k == "body") then
      table.insert(args, "--" .. k:gsub("_", "-"))
      table.insert(args, v)
    end
  end
  if opts.title then
    table.insert(args, vim.trim(opts.title))
  end
  if opts.body then
    table.insert(args, vim.trim(opts.body))
  end
  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()

  local out = ""
  local err = ""

  local proc
  proc = vim.loop.spawn(
    "notify-send",
    {
      stdio = { nil, stdout, stderr },
      args = args,
    },
    vim.schedule_wrap(function(code, _signal) -- on exit
      stdout:close()
      stderr:close()
      proc:close()

      if code ~= 0 then
        return Util.error("notify-send failed: %s", err)
      else
        self.notif = vim.trim(out)
      end
    end)
  )

  vim.loop.read_start(stdout, function(_, data)
    if data then
      out = out .. data
    end
  end)
  vim.loop.read_start(stderr, function(_, data)
    if data then
      err = err .. data
    end
  end)
end

function NotifySendView:show()
  ---@type NotifySendMsg[]
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
        opts = m.opts,
      })
    end
  end
  self:clear()

  for _, msg in ipairs(todo) do
    self:_notify(msg)
  end
end

function NotifySendView:hide()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
    self.win = nil
  end
end

return NotifySendView
