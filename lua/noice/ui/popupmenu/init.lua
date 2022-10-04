local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")

local M = {}

---@class PopupmenuBackend
---@field setup fun()
---@field on_show fun(state: Popupmenu)
---@field on_select fun(state: Popupmenu)
---@field on_hide fun()

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

---@type PopupmenuBackend
M.backend = nil

function M.setup()
  if Config.options.popupmenu.backend == "cmp" then
    M.backend = require("noice.ui.popupmenu.cmp")
  end
  M.backend.setup()
end
M.setup = Util.once(M.setup)

---@param items string[][]
function M.on_show(_, items, selected, row, col, grid)
  M.state = {
    items = items,
    visible = true,
    selected = selected,
    row = row,
    col = col,
    grid = grid,
  }
  M.setup()
  M.backend.on_show(M.state)
end

function M.on_select(_, selected)
  M.state.selected = selected
  M.state.visible = true
  M.backend.on_select(M.state)
end

function M.on_hide()
  M.state.visible = false
  M.backend.on_hide()
end

return M
