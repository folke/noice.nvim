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

---@param renderer Renderer
local function get_popup(renderer)
  ---@type NuiPopup
  local popup = renderer.popup
  if popup and popup.bufnr and vim.api.nvim_buf_is_valid(popup.bufnr) then
    return popup
  end

  renderer.popup = setup({})
  return renderer.popup
end

---@param renderer Renderer
return function(renderer)
  local popup = get_popup(renderer)
  if renderer.visible then
    popup:show()
    if renderer.opts.filetype then
      vim.api.nvim_buf_set_option(popup.bufnr, "filetype", renderer.opts.filetype)
    end
    renderer.message:render(popup.bufnr, Config.ns)
    popup:update_layout({
      position = {
        row = vim.o.lines - 1,
        col = 0,
      },
      size = {
        height = renderer.message:height(),
        width = vim.o.columns,
      },
    })
  else
    popup:hide()
  end
end
