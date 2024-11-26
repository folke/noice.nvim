local require = require("noice.util.lazy")

local Api = require("noice.api")
local Cmdline = require("noice.ui.cmdline")
local Util = require("noice.util")
local uv = vim.uv or vim.loop

-- HACK: a bunch of hacks to make Noice behave
local M = {}

---@type fun()[]
M._disable = {}

function M.reset_augroup()
  M.group = vim.api.nvim_create_augroup("noice.hacks", { clear = true })
end

function M.enable()
  M.reset_augroup()
  M.fix_cmp()
  M.fix_vim_sleuth()
  -- M.fix_redraw()

  -- Hacks for Neovim < 0.10
  if vim.fn.has("nvim-0.10") == 0 then
    M.fix_incsearch()
  end
end

function M.fix_redraw()
  local timer = uv.new_timer()
  timer:start(
    0,
    30,
    vim.schedule_wrap(function()
      if Util.is_exiting() then
        return timer:stop()
      end
      if not Util.is_search() then
        Util.redraw()
      end
    end)
  )
  table.insert(M._disable, function()
    timer:stop()
    timer:close()
  end)
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

M.SPECIAL = "Þ"
---@deprecated
function M.cmdline_force_redraw()
  if vim.fn.has("nvim-0.11") == 1 then
    -- no longer needed on nightly
    return
  end
  if not require("noice.util.ffi").cmdpreview then
    return
  end

  -- HACK: this will trigger redraw during substitute and cmdpreview
  vim.api.nvim_feedkeys(M.SPECIAL .. Util.BS, "n", true)
end

---@type string?
M._guicursor = nil
---@deprecated
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

---@deprecated
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

---@param modname string
---@param fn fun(mod)
function M.on_module(modname, fn)
  if type(package.loaded[modname]) == "table" then
    return fn(package.loaded[modname])
  end
  package.preload[modname] = function()
    package.preload[modname] = nil
    package.loaded[modname] = nil
    local mod = require(modname)
    fn(mod)
    return mod
  end
end

return M
