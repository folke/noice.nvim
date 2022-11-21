local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")
local Menu = require("nui.menu")
local Api = require("noice.api")
local NuiLine = require("nui.line")
local Scrollbar = require("noice.view.scrollbar")

local M = {}
---@type NuiMenu|NuiTree
M.menu = nil

---@type NoiceScrollbar
M.scroll = nil

function M.setup() end

---@param state Popupmenu
function M.align(state)
  local max_width = 0
  for _, item in ipairs(state.items) do
    max_width = math.max(max_width, item.text:width())
  end
  for _, item in ipairs(state.items) do
    local width = item.text:width()
    if width < max_width then
      item.text:append(string.rep(" ", max_width - width))
    end
  end
  return max_width
end

---@param item CompleteItem
---@param prefix? string
function M.format_abbr(item, prefix)
  local text = item.abbr or item.word
  if prefix and text:lower():find(prefix:lower(), 1, true) == 1 then
    item.text:append(text:sub(1, #prefix), "NoicePopupmenuMatch")
    item.text:append(text:sub(#prefix + 1), "NoiceCompletionItemWord")
  else
    item.text:append(text, "NoiceCompletionItemWord")
  end
end

---@param item CompleteItem
function M.format_menu(item)
  if item.menu and item.menu ~= "" then
    item.text:append(" ")
    item.text:append(item.menu, "NoiceCompletionItemMenu")
  end
end

---@param item CompleteItem
function M.format_kind(item)
  if item.kind and item.kind ~= "" then
    local hl_group = "NoiceCompletionItemKind" .. item.kind
    local icon = Config.options.popupmenu.kind_icons[item.kind]
    item.text:append(" ")
    if icon then
      item.text:append(vim.trim(icon) .. " ", hl_group)
    end
    item.text:append(item.kind, hl_group)
  end
end

---@param state Popupmenu
function M.opts(state)
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
        if pos.screenpos.row == vim.go.lines then
          opts.position.row = opts.position.row - 1
          opts.anchor = "SW"
        end
      end
    else
      opts.relative = { type = "cursor" }
      opts.position = {
        row = 1,
        col = -padding.left,
      }
    end
  end

  -- manage left/right padding on the line
  -- otherwise the selected CursorLine does not extend to the edges
  if opts.border and opts.border.padding then
    opts.border.padding = vim.tbl_deep_extend("force", {}, padding, { left = 0, right = 0 })
    if opts.size and type(opts.size.width) == "number" then
      opts.size.width = opts.size.width + padding.left + padding.right
    end
  end

  return opts, padding
end

---@param state Popupmenu
function M.show(state)
  M.on_hide()
  local is_cmdline = state.grid == -1
  local opts, padding = M.opts(state)

  ---@type string?
  local prefix = nil

  if is_cmdline then
    prefix = vim.fn.getcmdline():sub(state.col + 1, vim.fn.getcmdpos() - 1)
  elseif #state.items > 0 then
    prefix = state.items[1].word
    for _, item in ipairs(state.items) do
      for i = 1, #prefix do
        if prefix:sub(i, i) ~= item.word:sub(i, i) then
          prefix = prefix:sub(1, i - 1)
          break
        end
      end
    end
  end

  for _, item in ipairs(state.items) do
    if type(item) == "string" then
      item = { word = item }
    end
    item.text = NuiLine()
    if padding.left then
      item.text:append(string.rep(" ", padding.left))
    end
  end

  local max_width = 0
  for _, format in ipairs({ M.format_abbr, M.format_menu, M.format_kind }) do
    for _, item in ipairs(state.items) do
      format(item, prefix)
    end
    max_width = M.align(state)
  end

  for _, item in ipairs(state.items) do
    if padding.right then
      item.text:append(string.rep(" ", padding.right))
    end
  end

  opts = vim.tbl_deep_extend(
    "force",
    opts,
    Util.nui.get_layout({
      width = max_width + 1, -- +1 for scrollbar
      height = #state.items,
    }, opts)
  )

  ---@type NuiTreeNode[]
  local items = vim.tbl_map(function(item)
    return Menu.item(item)
  end, state.items)
  for i, item in ipairs(items) do
    item._index = i
  end

  if M.menu then
    M.menu._.items = items
    M.menu.tree:set_nodes(items)
    M.menu.tree:render()
    M.menu:update_layout(opts)
  else
    M.create(items, opts)
  end

  -- redraw is needed when in blocking mode
  if Util.is_blocking() then
    Util.redraw()
  end

  M.on_select(state)
end

---@param opts _.NuiPopupOptions
---@param items NuiTreeNode[]
function M.create(items, opts)
  M.menu = Menu(opts, {
    lines = items,
  })
  M.menu:mount()
  Util.tag(M.menu.bufnr, "popupmenu")
  if M.menu.border then
    Util.tag(M.menu.border.bufnr, "popupmenu.border")
  end

  M.scroll = Scrollbar({
    winnr = M.menu.winid,
    padding = Util.nui.normalize_padding(opts.border),
  })
  M.scroll:mount()
end

---@param state Popupmenu
function M.on_show(state)
  M.show(state)
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
