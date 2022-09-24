local Util = require("noice.util")

-- HACK: a bunch of hacks to make Noice behave
local M = {}

function M.setup()
  M.fix_incsearch()
  M.fix_getchar()
  M.fix_notify()
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

---@see https://github.com/neovim/neovim/issues/20311
function M.fix_getchar()
  local Scheduler = require("noice.scheduler")
  local Cmdline = require("noice.ui.cmdline")

  local function wrap(fn)
    return function(...)
      local args = { ... }
      return Scheduler.run_instant(function()
        Cmdline.on_show("cmdline_show", {}, 1, ">", "", 0, 1)
        ---@type any
        local ret = fn(unpack(args))
        Cmdline.on_hide(nil, 1)
        return ret
      end)
    end
  end

  vim.fn.getchar = wrap(vim.fn.getchar)
  vim.fn.getcharstr = wrap(vim.fn.getcharstr)
end

-- Allow nvim-notify to behave inside instant events
function M.fix_notify()
  vim.schedule(Util.protect(function()
    local NotifyService = require("notify.service")
    ---@type NotificationService
    local meta = getmetatable(NotifyService(require("notify")._config()))
    local push = meta.push
    meta.push = function(self, notif)
      ---@type buffer
      local buf = push(self, notif)

      -- run animator and re-render instantly when inside instant events
      if require("noice.scheduler").in_instant_event() then
        pcall(self._animator.render, self._animator, self._pending, 1 / self._fps)
        self._buffers[notif.id]:render()
      end
      return buf
    end
  end))
end

return M
