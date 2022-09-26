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
  local Manager = require("noice.manager")
  local Cmdline = require("noice.ui.cmdline")

  local function wrap(fn, skip)
    return function(...)
      local args = { ... }
      if skip and skip(unpack(args)) then
        return fn(unpack(args))
      end

      local instant = require("noice.instant").start()

      Cmdline.on_show("cmdline_show", {}, 1, ">", "", 0, 1)
      ---@type any
      local ret = fn(unpack(args))

      instant.stop()

      Manager.remove(Cmdline.message)
      Manager.clear({ event = "msg_show", kind = { "echo", "echomsg" } })
      return ret
    end
  end

  local function skip(expr)
    return expr ~= nil
  end
  vim.fn.getchar = wrap(vim.fn.getchar, skip)
  vim.fn.getcharstr = wrap(vim.fn.getcharstr, skip)
  vim.fn.inputlist = wrap(vim.fn.inputlist)
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
      if require("noice.instant").in_instant() then
        pcall(self._animator.render, self._animator, self._pending, 1 / self._fps)
        self._buffers[notif.id]:render()
      end
      return buf
    end
  end))
end

return M
