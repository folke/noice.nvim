local require = require("noice.util.lazy")

local Util = require("noice.util")
local Router = require("noice.message.router")
local Api = require("noice.api")
local Cmdline = require("noice.ui.cmdline")

-- HACK: a bunch of hacks to make Noice behave
local M = {}

---@type fun()[]
M._disable = {}

function M.reset_augroup()
  M.group = vim.api.nvim_create_augroup("noice.hacks", { clear = true })
end

function M.enable()
  M.reset_augroup()
  M.fix_incsearch()
  M.fix_input()
  M.fix_redraw()
  M.fix_cmp()
  M.fix_vim_sleuth()
end

function M.fix_vim_sleuth()
  vim.g.sleuth_noice_heuristics = 0
end

function M.disable()
  M.reset_augroup()
  for _, fn in pairs(M._disable) do
    fn()
  end
  M._disable = {}
end

-- start a timer that checks for vim.v.hlsearch.
-- Clears search count and stops timer when hlsearch==0
function M.fix_nohlsearch()
  M.fix_nohlsearch = Util.interval(30, function()
    if vim.o.hlsearch and vim.v.hlsearch == 0 then
      local m = require("noice.ui.msg").get("msg_show", "search_count")
      require("noice.message.manager").remove(m)
    end
  end, {
    enabled = function()
      return vim.o.hlsearch and vim.v.hlsearch == 1
    end,
  })
  M.fix_nohlsearch()
end

---@see https://github.com/neovim/neovim/issues/20793
function M.draw_cursor()
  require("noice.util.ffi").setcursor_mayforce(true)
end

---@see https://github.com/neovim/neovim/issues/17810
function M.fix_incsearch()
  ---@type integer|nil
  local conceallevel

  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = M.group,
    callback = function(event)
      if event.match == "/" or event.match == "?" then
        conceallevel = vim.wo.conceallevel
        vim.opt_local.conceallevel = 0
      end
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = M.group,
    callback = function(event)
      if conceallevel and (event.match == "/" or event.match == "?") then
        vim.opt_local.conceallevel = conceallevel
        conceallevel = nil
      end
    end,
  })
end

-- we need to intercept redraw so we can safely ignore message triggered by redraw
-- This wraps vim.cmd, nvim_cmd, nvim_command and nvim_exec
---@see https://github.com/neovim/neovim/issues/20416
M.inside_redraw = false
function M.fix_redraw()
  local nvim_cmd = vim.api.nvim_cmd

  local function wrap(fn, ...)
    local inside_redraw = M.inside_redraw

    M.inside_redraw = true

    ---@type boolean, any
    local ok, ret = pcall(fn, ...)

    -- check if the ui needs updating
    Util.try(Router.update)

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

  table.insert(M._disable, function()
    vim.api.nvim_cmd = nvim_cmd
    vim.api.nvim_command = nvim_command
    vim.api.nvim_exec = nvim_exec
  end)
end

---@see https://github.com/neovim/neovim/issues/20311
M.before_input = false
function M.fix_input()
  local function wrap(fn, skip)
    return function(...)
      if skip and skip(...) then
        return fn(...)
      end

      -- make sure the cursor is drawn before blocking
      M.draw_cursor()

      local Manager = require("noice.message.manager")

      -- do any updates now before blocking
      M.before_input = true
      Router.update()

      ---@type boolean, any
      local ok, ret = pcall(fn, ...)

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
  local getchar = vim.fn.getchar
  local getcharstr = vim.fn.getcharstr
  local inputlist = vim.fn.inputlist
  -- local confirm = vim.fn.confirm

  vim.fn.getchar = wrap(vim.fn.getchar, skip)
  vim.fn.getcharstr = wrap(vim.fn.getcharstr, skip)
  vim.fn.inputlist = wrap(vim.fn.inputlist, nil)
  -- vim.fn.confirm = wrap(vim.fn.confirm, nil)

  table.insert(M._disable, function()
    vim.fn.getchar = getchar
    vim.fn.getcharstr = getcharstr
    vim.fn.inputlist = inputlist
    -- vim.fn.confirm = confirm
  end)
end

-- Fixes cmp cmdline position
function M.fix_cmp()
  M.on_module("cmp.utils.api", function(api)
    local get_cursor = api.get_cursor
    api.get_cursor = function()
      if api.is_cmdline_mode() then
        local pos = Api.get_cmdline_position()
        if pos then
          return { pos.bufpos.row, vim.fn.getcmdpos() - 1 }
        end
      end
      return get_cursor()
    end

    local get_screen_cursor = api.get_screen_cursor
    api.get_screen_cursor = function()
      if api.is_cmdline_mode() then
        local pos = Api.get_cmdline_position()
        if pos then
          local col = vim.fn.getcmdpos() - Cmdline.last().offset
          return { pos.screenpos.row, pos.screenpos.col + col }
        end
      end
      return get_screen_cursor()
    end

    table.insert(M._disable, function()
      api.get_cursor = get_cursor
      api.get_screen_cursor = get_screen_cursor
    end)
  end)
end

function M.cmdline_force_redraw()
  if not require("noice.util.ffi").cmdpreview then
    return
  end

  -- HACK: this will trigger redraw during substitute and cmdpreview,
  -- but when moving the cursor, the screen will be cleared until
  -- a new character is entered
  vim.api.nvim_input(" <bs>")
end

---@type string?
M._guicursor = nil
function M.hide_cursor()
  if M._guicursor == nil then
    M._guicursor = vim.go.guicursor
  end
  -- schedule this, since otherwise Neovide crashes
  vim.schedule(function()
    if M._guicursor then
      vim.go.guicursor = "a:NoiceHiddenCursor"
    end
  end)
  M._disable.guicursor = M.show_cursor
end

function M.show_cursor()
  if M._guicursor then
    if not Util.is_exiting() then
      vim.schedule(function()
        if M._guicursor and not Util.is_exiting() then
          -- we need to reset all first and then wait for some time before resetting the guicursor. See #114
          vim.go.guicursor = "a:"
          vim.cmd.redrawstatus()
          vim.go.guicursor = M._guicursor
          M._guicursor = nil
        end
      end)
    end
  end
end

---@param fn fun(mod)
function M.on_module(module, fn)
  if package.loaded[module] then
    return fn(package.loaded[module])
  end

  package.preload[module] = function()
    package.preload[module] = nil
    for _, loader in pairs(package.loaders) do
      local ret = loader(module)
      if type(ret) == "function" then
        local mod = ret()
        fn(mod)
        return mod
      end
    end
  end
end

return M
