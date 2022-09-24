local M = {}

function M.setup()
  M.fix_incsearch()
  M.fix_getchar()
end

---@see https://github.com/neovim/neovim/issues/17810
function M.fix_incsearch()
  local group = vim.api.nvim_create_augroup("noice.incsearch", { clear = true })

  ---@type integer|string|nil
  local conceallevel

  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = group,
    callback = function(event)
      if event.match == "/" or event.match == "?" then
        conceallevel = vim.wo.conceallevel
        vim.wo.conceallevel = 0
      end
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = function(event)
      if conceallevel and (event.match == "/" or event.match == "?") then
        vim.wo.conceallevel = conceallevel
        conceallevel = nil
      end
    end,
  })
end

function M.fix_getchar()
  local Scheduler = require("noice.scheduler")
  local Cmdline = require("noice.ui.cmdline")

  local function wrap(fn)
    return function(...)
      local args = { ... }
      return Scheduler.run_instant(function()
        Cmdline.on_show("cmdline_show", {}, 1, ">", "", 0, 1)
        local ret = fn(unpack(args))
        Cmdline.on_hide(nil, 1)
        return ret
      end)
    end
  end

  vim.fn.getchar = wrap(vim.fn.getchar)
  vim.fn.getcharstr = wrap(vim.fn.getcharstr)
end

return M
