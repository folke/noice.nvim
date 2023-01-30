local Util = require("noice.util")
local Config = require("noice.config")
local Menu = require("nui.menu")
local NuiLine = require("nui.line")

local M = {}

local function default_item_kind(v)
  if v then
    if type(v.kind) == "string" then
      return v.kind
    elseif type(v) == "table" and v[2] and type(v[2].kind) == "string" then
      -- HACK: This is how CodeActions are structured, and there doesn't seem
      -- to be a cleaner way to do this.
      return v[2].kind
    end
  end
  return nil
end

function M.setup() end

function M.opts()
  local _opts = vim.deepcopy(Config.options.views.select or {})
  _opts.enter = true
  _opts.type = "popup"

  local opts = Util.nui.normalize(_opts)
  ---@cast opts _.NuiPopupOptions

  local padding = opts.border and opts.border.padding or {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  }

  if opts.position and opts.position.col then
    opts.position.col = opts.position.col - padding.left
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

---@param lines Popupmenu
function M.align(lines)
  local max_width = 0
  for _, item in ipairs(lines) do
    max_width = math.max(max_width, item.text:width())
  end
  for i, item in ipairs(lines) do
    local width = item.text:width()
    if i ~= 1 and width < max_width then
      item.text:append(string.rep(" ", max_width - width))
    end
  end
  return max_width
end

---@param item CompleteItem
function M.format_kind(item)
  local kind_icons
  if Config.options.select.kind_icons == true then
    kind_icons = Config.options.popupmenu.kind_icons or {}
  elseif not Config.options.select.kind_icons then
    kind_icons = {}
  else
    kind_icons = Config.options.select.kind_icons
  end

  if item.kind and item.kind ~= "" then
    local hl_group = "NoiceSelectItemKind" .. item.kind
    local icon = kind_icons[item.kind]
    item.text:append(" ")
    if icon then
      item.text:append(vim.trim(icon) .. " ", hl_group)
    end
    item.text:append(item.kind, hl_group)
  end
end

function M.on_show(_, items, select_opts, on_selected)
  if #items == 0 then
    return
  end

  select_opts = select_opts or {}
  local format_item = select_opts.format_item or tostring
  local get_item_kind = select_opts.item_kind or default_item_kind
  local prompt = select_opts.prompt
  local kind = select_opts.kind

  local opts, padding = M.opts()
  local lines = {}

  if prompt then
    local prompt_text = NuiLine()
    prompt_text:append(prompt)
    local menu_item = Menu.separator(prompt_text)
    menu_item.kind = Config.options.select.kind_aliases[kind] or kind
    M.format_kind(menu_item)
    table.insert(lines, menu_item)
  end

  for i, item in ipairs(items) do
    local text = NuiLine()
    local item_text, _ = format_item(item):gsub("[\n\r]+", " ")
    text:append(string.rep(" ", padding.left))
    text:append(item_text, "NoiceSelectItem")

    local item_kind = get_item_kind(item) or kind
    item_kind = Config.options.select.kind_aliases[item_kind] or item_kind

    local menu_item = Menu.item(text, {
      id = i,
      kind = item_kind,
      data = item,
    })
    M.format_kind(menu_item)
    table.insert(lines, menu_item)
  end

  local max_width = M.align(lines)

  for i, item in ipairs(lines) do
    if i ~= 1 and padding.right then
      item.text:append(string.rep(" ", padding.right))
    end
  end

  opts = vim.tbl_deep_extend(
    "force",
    opts,
    Util.nui.get_layout({
      width = max_width + 1, -- +1 for scrollbar
      height = #lines,
    }, opts)
  )

  local menu = Menu(opts, {
    lines = lines,
    on_submit = function(item)
      if on_selected and item.data then
        on_selected(item.data)
      end
    end,
  })
  menu:mount()
end

return M
