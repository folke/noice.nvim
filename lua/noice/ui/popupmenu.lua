local Config = require("noice.config")
local Util = require("noice.util")
local Cmdline = require("noice.ui.cmdline")

local M = {}

---@type cmp.CustomEntriesView
M.view = nil

M.no_cmdline_mode = false

function M.fix_cmp()
  local orig = require("cmp.utils.api").is_cmdline_mode
  require("cmp.utils.api").is_cmdline_mode = function()
    return orig() and not M.no_cmdline_mode
  end
  M.fix_cmp = function() end
end

---@param items string[][]
function M.on_show(_, items, selected)
  M.fix_cmp()
  if not M.view then
    M.view = require(
      "cmp.view." .. (Config.options.cmdline.menu == "wild" and "wildmenu" or "custom") .. "_entries_view"
    ).new()
  end

  require("cmp.config").set_onetime({
    preselect = require("cmp.types").cmp.PreselectMode.Item,
    completion = {
      completeopt = "noselect",
    },
  })

  local source = require("cmp.source").new("noice", {})
  local ctx = require("cmp.context").new()

  local Entry = require("cmp.entry")
  local entries = {}

  for i, item in ipairs(items) do
    local word, _, menu, info = unpack(item) --[[@as string ]]
    table.insert(
      entries,
      Entry.new(ctx, source, {
        label = word,
        menu = menu,
        info = info,
        preselect = i == selected + 1,
      })
    )
  end
  local cursor = Cmdline.message.cursor
  if cursor then
    local win = vim.fn.bufwinid(cursor.buf)
    if win ~= -1 then
      M.no_cmdline_mode = true
      vim.api.nvim_win_set_cursor(win, { cursor.buf_line, cursor.col })
      vim.api.nvim_win_call(win, function()
        M.view:open(2, entries)
        Util.redraw()
      end)
      M.no_cmdline_mode = false
    end
  end
end

function M.on_select(_, selected)
  if M.view then
    M.view:_select(selected + 1, { behavior = require("cmp.types").cmp.SelectBehavior.Select })
  end
end

function M.on_hide()
  if M.view then
    M.view:close()
  end
end

function M.update()
  if not M.popup then
    return
  end
end

return M
