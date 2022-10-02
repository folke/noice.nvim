local require = require("noice.util.lazy")

local Util = require("noice.util")

-- HACK: a bunch of hacks to make Noice behave
local M = {}

function M.setup()
  M.fix_incsearch()
  M.fix_getchar()
  M.fix_notify()
  M.fix_nohlsearch()
  M.fix_redraw()
end

-- clear search_count on :nohlsearch
function M.fix_nohlsearch()
  vim.api.nvim_create_autocmd("CmdlineLeave", {
    callback = function()
      local cmd = vim.fn.getcmdline()
      if cmd:find("noh") == 1 then
        require("noice.manager").clear({ kind = "search_count" })
      end
    end,
  })
end

---@see https://github.com/neovim/neovim/issues/17810
function M.fix_incsearch()
  ---@type integer|string|nil
  local conceallevel

  vim.api.nvim_create_autocmd("CmdlineEnter", {
    callback = function(event)
      if event.match == "/" or event.match == "?" then
        conceallevel = vim.wo.conceallevel
        vim.wo.conceallevel = 0
      end
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    callback = function(event)
      if conceallevel and (event.match == "/" or event.match == "?") then
        vim.wo.conceallevel = conceallevel
        conceallevel = nil
      end
    end,
  })
end

-- we need to intercept redraw so we can safely ignore message triggered by redraw
-- This wraps vim.cmd, nvim_cmd, nvim_command and nvim_exec
---@see https://github.com/neovim/neovim/issues/20416
M.inside_redraw = false
M.block_redraw = false
function M.fix_redraw()
  local nvim_cmd = vim.api.nvim_cmd

  local function wrap(fn, ...)
    local inside_redraw = M.inside_redraw

    M.inside_redraw = true

    ---@type boolean, any
    local ok, ret = pcall(fn, ...)

    if not inside_redraw then
      M.inside_redraw = false
    end

    if ok then
      return ret
    end
    error(ret)
  end

  vim.api.nvim_cmd = function(cmd, ...)
    if type(cmd) == "table" and cmd.cmd and cmd.cmd == "redraw" then
      return wrap(nvim_cmd, cmd, ...)
    else
      return nvim_cmd(cmd, ...)
    end
  end

  local nvim_command = vim.api.nvim_command
  vim.api.nvim_command = function(cmd, ...)
    if cmd == "redraw" then
      return wrap(nvim_command, cmd, ...)
    else
      return nvim_command(cmd, ...)
    end
  end

  local nvim_exec = vim.api.nvim_exec
  vim.api.nvim_exec = function(cmd, ...)
    if type(cmd) == "string" and cmd:find("redraw") then
      -- WARN: this will potentially lose messages before or after the redraw ex command
      -- example: echo "foo" | redraw | echo "bar"
      -- the 'foo' message will be lost
      return wrap(nvim_exec, cmd, ...)
    else
      return nvim_exec(cmd, ...)
    end
  end
end

---@see https://github.com/neovim/neovim/issues/20311
M.before_input = false
function M.fix_getchar()
  local function wrap(fn, skip)
    return function(...)
      local args = { ... }
      if skip and skip(unpack(args)) then
        return fn(unpack(args))
      end

      local Manager = require("noice.manager")

      -- do any updates now before blocking
      M.before_input = true
      require("noice.router").update()

      ---@type boolean, any
      local ok, ret = pcall(fn, unpack(args))

      -- clear any message right after input
      Manager.clear({ event = "msg_show", kind = { "echo", "echomsg", "" } })

      M.before_input = false
      if ok then
        return ret
      end
      error(ret)
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
      if Util.is_blocking() then
        pcall(self._animator.render, self._animator, self._pending, 1 / self._fps)
        self._buffers[notif.id]:render()
      end
      return buf
    end
  end))
end

return M
