local require = require("noice.util.lazy")

local Popupmenu = require("noice.ui.popupmenu")

local cmp = require("cmp")
local cmp_config = require("cmp.config")

---@class NoiceCmpSource: cmp.Source
---@field before_line string
---@field items {label: string}[]
local source = {}
source.new = function()
  return setmetatable({
    items = {},
  }, { __index = source })
end

function source:complete(_params, callback)
  if not Popupmenu.state.visible then
    return callback()
  end

  local items = {}

  for i, item in ipairs(Popupmenu.state.items) do
    table.insert(items, {
      label = item.word,
      kind = cmp.lsp.CompletionItemKind.Variable,
      preselect = i == (Popupmenu.state.selected + 1),
    })
  end

  callback({ items = items, isIncomplete = true })
end

local M = {}

function M.setup()
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

function M.on_show()
  local config = vim.deepcopy(cmp.get_config())
  config.sources = cmp.config.sources({ { name = "noice_popupmenu" } })
  cmp.core:prepare()
  cmp.complete({
    config = config,
  })
end

function M.on_select()
  M.on_show()
end

function M.on_hide()
  -- cmp.close()
end

return M
