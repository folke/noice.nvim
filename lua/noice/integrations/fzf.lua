local require = require("noice.util.lazy")

local Config = require("noice.config")
local Format = require("noice.text.format")
local Manager = require("noice.message.manager")
local builtin = require("fzf-lua.previewer.builtin")
local fzf = require("fzf-lua")

local M = {}

---@alias NoiceEntry {message: NoiceMessage, ordinal: string, display: string}

---@param message NoiceMessage
---@return NoiceEntry
function M.entry(message)
  message = Format.format(message, "fzf")
  local line = message._lines[1]
  local hl = { message.id .. " " } ---@type string[]
  for _, text in ipairs(line._texts) do
    ---@type string?
    local hl_group = text.extmark and text.extmark.hl_group
    hl[#hl + 1] = hl_group and fzf.utils.ansi_from_hl(hl_group, text:content()) or text:content()
  end
  return {
    message = message,
    ordinal = message:content(),
    display = table.concat(hl, ""),
  }
end

function M.find()
  local messages = Manager.get(Config.options.commands.history.filter, {
    history = true,
    sort = true,
    reverse = true,
  })
  ---@type table<number, NoiceEntry>
  local ret = {}

  for _, message in ipairs(messages) do
    ret[message.id] = M.entry(message)
  end

  return ret
end

---@param messages table<number, NoiceEntry>
function M.previewer(messages)
  local previewer = builtin.buffer_or_file:extend()

  function previewer:new(o, opts, fzf_win)
    previewer.super.new(self, o, opts, fzf_win)
    self.title = "Noice"
    setmetatable(self, previewer)
    return self
  end

  function previewer:parse_entry(entry_str)
    local id = tonumber(entry_str:match("^%d+"))
    local entry = messages[id]
    assert(entry, "No message found for entry: " .. entry_str)
    return entry
  end

  function previewer:populate_preview_buf(entry_str)
    local buf = self:get_tmp_buffer()
    local entry = self:parse_entry(entry_str)
    assert(entry, "No message found for entry: " .. entry_str)

    ---@type NoiceMessage
    local m = Format.format(entry.message, "fzf_preview")
    m:render(buf, Config.ns)

    self:set_preview_buf(buf)
    self.win:update_title(" Noice ")
    self.win:update_scrollbar()
  end

  return previewer
end

---@param opts? table<string, any>
function M.open(opts)
  local messages = M.find()
  opts = vim.tbl_deep_extend("force", opts or {}, {
    prompt = false,
    winopts = {
      title = " Noice ",
      title_pos = "center",
      preview = {
        title = " Noice ",
        title_pos = "center",
      },
    },
    previewer = M.previewer(messages),
    fzf_opts = {
      ["--no-multi"] = "",
      ["--with-nth"] = "2..",
    },
    actions = {
      default = function() end,
    },
  })
  local lines = vim.tbl_map(function(entry)
    return entry.display
  end, vim.tbl_values(messages))
  return fzf.fzf_exec(lines, opts)
end

return M
