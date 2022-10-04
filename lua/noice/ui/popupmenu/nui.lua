local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")
local Menu = require("nui.menu")
local NuiLine = require("nui.line")

local M = {}
---@class NuiMenu
M.menu = nil

function M.setup() end

---@param state Popupmenu
function M.create(state)
  M.on_hide()

  local height = vim.api.nvim_get_option("pumheight")
  height = height ~= 0 and height or #state.items
  height = math.min(height, #state.items)

  ---@type NuiPopupOptions
  local opts = vim.tbl_deep_extend("force", Config.options.views.popupmenu or {}, {
    enter = false,
    relative = "cursor",
    position = {
      row = 1,
      col = 0,
    },
    size = {
      height = height,
    },
  })
  if opts.win_options and opts.win_options.winhighlight then
    opts.win_options.winhighlight = Util.get_win_highlight(opts.win_options.winhighlight)
  end

  ---@type string?
  local prefix = nil

  -- check if we need to anchor to the cmdline
  if state.grid == -1 then
    local cursor = Util.cursor.get_cmdline_cursor()
    if cursor then
      prefix = vim.fn.getcmdline():sub(state.col + 1, vim.fn.getcmdpos())
      opts.relative = "editor"
      opts.position = {
        row = cursor.screen_cursor[1],
        col = cursor.screen_cursor[2] - vim.fn.getcmdpos() + state.col + 1,
      }
    end
  end

  M.menu = Menu(opts, {
    lines = vim.tbl_map(
      ---@param item CompleteItem|string
      function(item)
        if type(item) == "string" then
          item = { word = item }
        end
        local text = item.abbr or item.word
        local line = NuiLine()
        if prefix and text:lower():find(prefix:lower(), 1, true) == 1 then
          line:append(prefix, "PmenuMatch")
          line:append(text:sub(#prefix + 1))
        else
          line:append(text)
        end
        return Menu.item(line, item)
      end,
      state.items
    ),
  })
  M.menu:mount()
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
  end
end

function M.on_hide()
  if M.menu then
    M.menu:unmount()
    M.menu = nil
  end
end

return M
