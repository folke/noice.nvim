local require = require("noice.util.lazy")

local Manager = require("noice.message.manager")
local NuiText = require("nui.text")
local Util = require("noice.util")
local View = require("noice.view")

local defaults = {
  title = "Notification",
  merge = false,
  level = nil, -- vim.log.levels.INFO,
  replace = false,
}

---@class SnacksView: NoiceView
---@field notif_id? string|number
---@field super NoiceView
---@diagnostic disable-next-line: undefined-field
local M = View:extend("SnacksView")

function M.dismiss()
  Snacks.notifier.hide()
end

function M:is_available()
  return _G.Snacks ~= nil and Snacks.config.notifier.enabled
end

function M:update_options()
  self._opts = vim.tbl_deep_extend("force", defaults, self._opts)
end

---@param messages NoiceMessage[]
---@param content? string
function M:style(messages, content)
  ---@type snacks.notifier.render
  return function(buf, notif, ctx)
    vim.bo[buf].modifiable = true
    ctx.notifier:get_render()(buf, notif, ctx)
    vim.bo[buf].modifiable = false

    Util.tag(buf, "notify")

    ---@type string[]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    local text = table.concat(lines, "\n")
    local idx = content and text:find(content, 1, true) or nil

    if idx then
      -- we found the offset of the content as a string
      local before = text:sub(1, idx - 1)
      local offset = #vim.split(before, "\n")
      local offset_col = #before:match("[^\n]*$")

      -- in case the content starts in the middle of the line,
      -- we need to add a fake prefix to the first line of the first message
      -- see #375
      if offset_col > 0 then
        messages = vim.deepcopy(messages)
        table.insert(messages[1]._lines[1]._texts, 1, NuiText(string.rep(" ", offset_col)))
      end

      -- do our rendering
      self:render(buf, { offset = offset, highlight = true, messages = messages })
      -- in case we didn't find the offset, we won't highlight anything
    end
  end
end

---@param msg NotifyMsg
function M:_notify(msg)
  ---@type snacks.notifier.Notif.opts
  local opts = {
    msg = msg.content or "",
    level = self._opts.level or msg.level,
    title = msg.title or self._opts.title,
    timeout = self._opts.timeout,
    id = self._opts.replace and self.notif_id or nil,
    keep = function()
      return Util.is_blocking() and true or false
    end,
    style = Util.protect(self:style(msg.messages, msg.content)),
  }

  if msg.opts then
    opts = vim.tbl_deep_extend("force", opts, msg.opts)
    if msg.opts.id then
      local m = Manager.get_by_id(msg.opts.id)
      opts.id = m and m.opts.notify_id or msg.opts.id
      if type(opts.id) == "table" and opts.id.id then
        opts.id = opts.id.id
      end
    end
  end

  self.notif_id = Snacks.notifier.notify(opts.msg, opts.level, opts)
  for _, m in ipairs(msg.messages) do
    m.opts.notify_id = self.notif_id
  end
end

function M:show()
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
        opts = m.opts,
      })
    end
  end
  self:clear()

  for _, msg in ipairs(todo) do
    self:_notify(msg)
  end
end

function M:hide()
  if self._opts.merge and self.notif_id then
    Snacks.notifier.hide(self.notif_id)
    self.notif_id = nil
  end
end

return M
