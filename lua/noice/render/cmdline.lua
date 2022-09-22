local Config = require("noice.config")

local function setup(opts)
  local Popup = require("nui.popup")

  opts = vim.tbl_deep_extend("force", {}, {
    relative = "editor",
    position = {
      row = vim.o.lines - 1,
      col = 0,
    },
    size = {
      height = 1,
      width = vim.o.columns,
    },
    border = {
      style = "none",
    },
    win_options = {
      winhighlight = "Normal:MsgArea",
    },
  }, opts or {})

  local popup = Popup(opts)

  -- mount/open the component
  popup:mount()
  return popup
end

---@param view View
local function get_popup(view)
  ---@type NuiPopup
  local popup = view.popup
  if popup and popup.bufnr and vim.api.nvim_buf_is_valid(popup.bufnr) then
    return popup
  end

  view.popup = setup({})
  return view.popup
end

---@param view View
return function(view)
  local popup = get_popup(view)
  if view.visible then
    popup:show()
    if view.opts.filetype then
      vim.api.nvim_buf_set_option(popup.bufnr, "filetype", view.opts.filetype)
    end
    view.message:render(popup.bufnr, Config.ns)
    popup:update_layout({
      position = {
        row = vim.o.lines - 1,
        col = 0,
      },
      size = {
        height = view.message:height(),
        width = vim.o.columns,
      },
    })
  else
    popup:hide()
  end
end
