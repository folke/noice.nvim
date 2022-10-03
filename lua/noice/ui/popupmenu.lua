local require = require("noice.util.lazy")

local Util = require("noice.util")
local cmp = require("cmp")
local cmp_config = require("cmp.config")

local M = {}

---@class Popupmenu
---@field selected number
---@field col number
---@field row number
---@field grid number
---@field items string[][]
M.state = {
  visible = false,
  items = {},
}

---@class NoiceCmpSource: cmp.Source
---@field before_line string
---@field items {label: string}[]
local source = {}
source.new = function()
  return setmetatable({
    items = {},
  }, { __index = source })
end

function source:get_keyword_pattern()
  return [=[[^[:blank:]]*]=]
end

function source:complete(_params, callback)
  if not M.state.visible then
    return callback()
  end

  local items = {}

  for i, item in ipairs(M.state.items) do
    local word, _, _menu, _info = unpack(item) --[[@as string ]]
    table.insert(items, {
      label = word,
      kind = cmp.lsp.CompletionItemKind.Variable,
      preselect = i == (M.state.selected + 1),
    })
  end

  callback({ items = items, isIncomplete = true })
end

M.setup = function()
  vim.notify("Registering noice with cmp")
  cmp.register_source("noice_popupmenu", source.new())
  for _, mode in ipairs({ ":" }) do
    if not cmp_config.cmdline[mode] then
      cmp.setup.cmdline(mode, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "noice_popupmenu" },
        }),
      })
      cmp.core:prepare()
    end
  end
end
M.setup = Util.once(M.setup)

---@param items string[][]
function M.on_show(_, items, selected, row, col, grid)
  M.setup()
  M.state = {
    items = items,
    visible = true,
    selected = selected,
    row = row,
    col = col,
    grid = grid,
  }
  if not cmp.core.view:visible() then
    cmp.complete()
  end
end

function M.on_select(_, selected)
  M.state.selected = selected
  M.state.visible = true
  cmp.complete()
end

function M.on_hide()
  M.state.visible = false
end

return M
