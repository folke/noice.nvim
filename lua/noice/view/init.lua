local require = require("noice.util.lazy")

local Config = require("noice.config")
local ConfigViews = require("noice.config.views")
local Util = require("noice.util")
local Object = require("nui.object")
local Format = require("noice.text.format")

---@class NoiceViewBaseOptions
---@field buf_options? table<string,any>
---@field backend string
---@field fallback string Fallback view in case the backend could not be loaded
---@field format? NoiceFormat|string
---@field align? NoiceAlign
---@field lang? string
---@field view string

---@alias NoiceViewOptions NoiceViewBaseOptions|NoiceNuiOptions|NoiceNotifyOptions

---@class NoiceView
---@field _tick number
---@field _messages NoiceMessage[]
---@field _id integer
---@field _opts NoiceViewOptions
---@field _view_opts NoiceViewOptions
---@field _route_opts NoiceViewOptions
---@field _visible boolean
---@field _instance "opts" | "view" | "backend"
---@overload fun(opts?: NoiceViewOptions): NoiceView
local View = Object("NoiceView")

---@type {view:NoiceView, opts:NoiceViewOptions}[]
View._views = {}

---@param view string
---@param opts NoiceViewOptions
function View.get_view(view, opts)
  local opts_orig = vim.deepcopy(opts)
  opts = vim.tbl_deep_extend("force", ConfigViews.get_options(view), opts or {}, { view = view })

  ---@diagnostic disable-next-line: undefined-field
  opts.backend = opts.backend or opts.render or view

  -- check if we already loaded this backend
  for _, v in ipairs(View._views) do
    if v.opts.view == opts.view then
      if v.view._instance == "opts" and vim.deep_equal(opts, v.opts) then
        return v.view
      end
      if v.view._instance == "view" then
        return v.view
      end
    end
    if v.opts.backend == opts.backend then
      if v.view._instance == "backend" then
        return v.view
      end
    end
  end

  local mod = require("noice.view.backend." .. opts.backend)
  ---@type NoiceView
  local ret = mod(opts)
  if not ret:is_available() and opts.fallback then
    return View.get_view(opts.fallback, opts_orig)
  end
  table.insert(View._views, { view = ret, opts = vim.deepcopy(opts) })
  return ret
end

local _id = 0
---@param opts? NoiceViewOptions
function View:init(opts)
  _id = _id + 1
  self._id = _id
  self._tick = 0
  self._messages = {}
  self._opts = opts or {}
  self._visible = false
  self._view_opts = vim.deepcopy(self._opts)
  self._instance = "opts"
  self:update_options()
end

function View:is_available()
  return true
end

function View:update_options() end

function View:check_options()
  ---@type NoiceViewOptions
  local old = vim.deepcopy(self._opts)
  self._opts = vim.tbl_deep_extend("force", vim.deepcopy(self._view_opts), self._route_opts or {})
  self:update_options()
  if not vim.deep_equal(old, self._opts) then
    self:reset(old, self._opts)
  end
end

---@param messages NoiceMessage[]
---@param opts? {dirty?:boolean, format?: boolean}
function View:display(messages, opts)
  opts = opts or {}
  local dirty = (#messages ~= #self._messages) or opts.dirty
  for _, m in ipairs(messages) do
    if m.tick > self._tick then
      self._tick = m.tick
      dirty = true
    end
  end

  if dirty then
    if opts.format == false then
      self._messages = messages
    else
      self:format(messages)
    end
    if #self._messages > 0 then
      self:check_options()

      Util.try(self.show, self)

      self._visible = true
    else
      self._visible = false
      self:hide()
    end
    return true
  end
  return false
end

---@param messages NoiceMessage[]
function View:format(messages)
  self._messages = vim.tbl_map(
    ---@param message NoiceMessage
    function(message)
      return require("noice.text.format").format(message, self._opts.format)
    end,
    messages
  )

  local width = self:width()
  for _, message in ipairs(self._messages) do
    Format.align(message, width, self._opts.align)
  end
end

---@param old NoiceViewOptions
---@param new NoiceViewOptions
function View:reset(old, new) end

function View:show()
  Util.error("Missing implementation `View:show()` for %s", self)
end

function View:hide()
  Util.error("Missing implementation `View:hide()` for %s", self)
end

---@param messages? NoiceMessage[]
function View:height(messages)
  local ret = 0
  for _, m in ipairs(messages or self._messages) do
    ret = ret + m:height()
  end
  return ret
end

---@param messages? NoiceMessage[]
function View:width(messages)
  local ret = 0
  for _, m in ipairs(messages or self._messages) do
    ret = math.max(ret, m:width())
  end
  return ret
end

function View:content()
  return table.concat(
    vim.tbl_map(
      ---@param m NoiceMessage
      function(m)
        return m:content()
      end,
      self._messages
    ),
    "\n"
  )
end

---@param buf number buffer number
---@param opts? {offset: number, highlight: boolean, messages?: NoiceMessage[]} line number (1-indexed), if `highlight`, then only highlight
function View:render(buf, opts)
  opts = opts or {}
  local linenr = opts.offset or 1

  if self._opts.buf_options then
    require("nui.utils")._.set_buf_options(buf, self._opts.buf_options)
  end

  if self._opts.lang and not vim.b[buf].ts_highlight then
    vim.treesitter.start(buf, self._opts.lang)
  end

  vim.api.nvim_buf_clear_namespace(buf, Config.ns, linenr - 1, -1)

  if not opts.highlight then
    vim.api.nvim_buf_set_lines(buf, linenr - 1, -1, false, {})
  end

  for _, m in ipairs(opts.messages or self._messages) do
    if opts.highlight then
      m:highlight(buf, Config.ns, linenr)
    else
      m:render(buf, Config.ns, linenr)
    end
    linenr = linenr + m:height()
  end
end

return View
