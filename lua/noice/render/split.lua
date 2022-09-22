local Config = require("noice.config")

local function setup(opts)
  local Split = require("nui.split")
  local event = require("nui.utils.autocmd").event

  opts = vim.tbl_deep_extend("force", {}, {
    enter = true,
    relative = "editor",
    position = "bottom",
    size = "20%",
    win_options = {
      winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
    },
  }, opts or {})

  local split = Split(opts)

  -- mount/open the component
  split:mount()

  -- unmount component when cursor leaves buffer
  split:on(event.BufLeave, function()
    split:unmount()
  end, { once = true })

  split:on({ event.BufWinLeave }, function()
    vim.schedule(function()
      split:unmount()
    end)
  end, { once = true })

  split:map("n", { "q", "<esc>" }, function()
    split:unmount()
  end, { remap = false, nowait = true })

  return split
end

---@param view View
local function get_split(view)
  ---@type NuiSplit
  local split = view.split
  if split and split.bufnr and vim.api.nvim_buf_is_valid(split.bufnr) then
    return split
  end

  view.split = setup({})
  return view.split
end

---@param view View
return function(view)
  view.message:render(get_split(view).bufnr, Config.ns)
end
