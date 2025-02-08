local require = require("noice.util.lazy")

---@module 'snacks'

local Config = require("noice.config")
local Format = require("noice.text.format")
local Manager = require("noice.message.manager")

local M = {}

function M.find()
  local messages = Manager.get(Config.options.commands.history.filter, {
    history = true,
    sort = true,
    reverse = true,
  })

  ---@param message NoiceMessage
  return vim.tbl_map(function(message)
    return {
      message = message,
      text = message._lines[1]:content(),
    }
  end, messages)
end

---@param item snacks.picker.Item
function M.format(item)
  local message = item.message --[[@as NoiceMessage]]
  message = Format.format(message, "snacks")
  return vim.tbl_map(function(text)
    return { text:content(), text.extmark and text.extmark.hl_group }
  end, message._lines[1]._texts)
end

---@type snacks.picker.preview
function M.preview(ctx)
  local message = ctx.item.message --[[@as NoiceMessage]]
  message = Format.format(message, "snacks_preview")
  ctx.preview:reset()
  vim.bo[ctx.buf].modifiable = true
  message:render(ctx.buf, Config.ns)
  vim.bo[ctx.buf].modifiable = false
end

---@type snacks.picker.Config
M.source = {
  source = "noice",
  finder = M.find,
  format = M.format,
  preview = M.preview,
}

---@param opts? snacks.picker.Config|{}
function M.open(opts)
  return Snacks.picker("noice", opts)
end

return M
