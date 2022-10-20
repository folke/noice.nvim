local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")
local Menu = require("nui.menu")
local Api = require("noice.api")
local NuiLine = require("nui.line")
local Scrollbar = require("noice.view.scrollbar")

local M = {}
---@type NuiMenu
M.menu = nil

---@type NoiceScrollbar
M.scroll = nil

function M.setup() end

---@param state Popupmenu
function M.create(state)
  M.on_hide()

  local is_cmdline = state.grid == -1

  local _opts = vim.deepcopy(Config.options.views.popupmenu or {})
  _opts.enter = false
  _opts.type = "popup"

  local opts = Util.nui.normalize(_opts)
  ---@cast opts _.NuiPopupOptions

  local padding = opts.border and opts.border.padding or {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  }

  local position_auto = not opts.position or opts.position.col == "auto"
  if position_auto then
    if is_cmdline then
      -- Anchor to the cmdline
      local pos = Api.get_cmdline_position()
      if pos then
        opts.relative = { type = "editor" }
        opts.position = {
          row = pos.screenpos.row,
          col = pos.screenpos.col + state.col - padding.left,
        }
      end
    else
      opts.relative = { type = "cursor" }
      opts.position = {
        row = 1,
        col = -padding.left,
      }
    end
  end

  ---@type string?
  local prefix = nil

  if is_cmdline then
    prefix = vim.fn.getcmdline():sub(state.col + 1, vim.fn.getcmdpos() - 1)
  end

  -- manage left/right padding on the line
  -- otherwise the selected CursorLine does not extend to the edges
  if opts.border and opts.border.padding then
    opts.border.padding = vim.tbl_deep_extend("force", {}, padding, { left = 0, right = 0 })
  end

  local max_width = 0

  local menu_items = vim.tbl_map(
    ---@param item CompleteItem|string
    function(item)
      if type(item) == "string" then
        item = { word = item }
      end
      local text = item.abbr or item.word
      local line = NuiLine()
      if padding.left then
        line:append(string.rep(" ", padding.left))
      end
      if prefix and text:lower():find(prefix:lower(), 1, true) == 1 then
        line:append(prefix, "PmenuMatch")
        line:append(text:sub(#prefix + 1))
      else
        line:append(text)
      end
      if padding.right then
        line:append(string.rep(" ", padding.right))
      end
      max_width = math.max(max_width, line:width())
      return Menu.item(line, item)
    end,
    state.items
  )

  opts = vim.tbl_deep_extend(
    "force",
    opts,
    Util.nui.get_layout({
      width = max_width + 1, -- +1 for scrollbar
      height = #state.items,
    }, opts)
  )

  M.menu = Menu(opts, { lines = menu_items })
  M.menu:mount()

  M.scroll = Scrollbar({
    winnr = M.menu.winid,
    border_size = Util.nui.get_border_size(opts.border),
  })
  M.scroll:mount()

  -- redraw is needed when in blocking mode
  if Util.is_blocking() then
    Util.redraw()
  end

  M.on_select(state)
end

---@param state Popupmenu
function M.on_show(state)
  M.create(state)
end

---@param state Popupmenu
function M.on_select(state)
  if M.menu and state.selected ~= -1 then
    vim.api.nvim_win_set_cursor(M.menu.winid, { state.selected + 1, 0 })
    vim.cmd([[do WinScrolled]])
  end
end

function M.on_hide()
  if M.menu then
    M.menu:unmount()
    M.menu = nil
  end
  if M.scroll then
    M.scroll:unmount()
    M.scroll = nil
  end
end

return M
