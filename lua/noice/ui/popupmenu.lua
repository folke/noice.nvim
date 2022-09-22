local Config = require("noice.config")

local M = {}

---@type cmp.CustomEntriesView
M.view = nil

function M.on_show(_, items, selected)
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
    local word, kind, menu, info = unpack(item)
    table.insert(
      entries,
      Entry.new(ctx, source, {
        label = word,
        kind = kind,
        menu = menu,
        info = info,
        preselect = i == selected + 1,
      })
    )
  end

  M.view:open(0, entries)
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
