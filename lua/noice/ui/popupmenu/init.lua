local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")

local M = {}

---@class PopupmenuBackend
---@field setup fun()
---@field on_show fun(state: Popupmenu)
---@field on_select fun(state: Popupmenu)
---@field on_hide fun()

---@class CompleteItem
---@field word string the text that will be inserted, mandatory
---@field abbr? string abbreviation of "word"; when not empty it is used in the menu instead of "word"
---@field menu? string extra text for the popup menu, displayed after "word" or "abbr"
---@field info? string more information about the item, can be displayed in a preview window
---@field kind? string single letter indicating the type of completion
---@field icase? boolean when non-zero case is to be ignored when comparing items to be equal; when omitted zero is used, thus items that only differ in case are added
---@field equal? boolean when non-zero, always treat this item to be equal when comparing. Which means, "equal=1" disables filtering of this item.
---@field dup? boolean when non-zero this match will be added even when an item with the same word is already present.
---@field empty? boolean when non-zero this match will be added even when it is an empty string
---@field user_data? any custom data which is associated with the item and available in |v:completed_item|; it can be any type; defaults to an empty string
---@field text? NuiLine

---@class Popupmenu
---@field selected number
---@field col number
---@field row number
---@field grid number
---@field items CompleteItem[]
M.state = {
  visible = false,
  items = {},
}

---@type PopupmenuBackend
M.backend = nil

function M.setup()
  if Config.options.popupmenu.backend == "cmp" then
    M.backend = require("noice.ui.popupmenu.cmp")
  elseif Config.options.popupmenu.backend == "nui" then
    M.backend = require("noice.ui.popupmenu.nui")
  end
  M.backend.setup()
end
M.setup = Util.once(M.setup)

---@param items string[][]
function M.on_show(_, items, selected, row, col, grid)
  local state = {
    items = vim.tbl_map(
      ---@param item string[]
      function(item)
        return {
          word = item[1],
          kind = item[2],
          menu = item[3],
          info = item[4],
        }
      end,
      items
    ),
    visible = true,
    selected = selected,
    row = row,
    col = col,
    grid = grid,
  }
  if not vim.deep_equal(state, M.state) then
    M.state = state
    M.setup()
    M.backend.on_show(M.state)
  end
end

function M.on_select(_, selected)
  if M.state.selected ~= selected then
    M.state.selected = selected
    M.state.visible = true
    M.backend.on_select(M.state)
  end
end

function M.on_hide()
  if M.state.visible then
    M.state.visible = false
    vim.schedule(function()
      if not M.state.visible then
        M.backend.on_hide()
      end
    end)
  end
end

return M
