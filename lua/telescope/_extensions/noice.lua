local require = require("noice.util.lazy")

local Config = require("noice.config")
local Manager = require("noice.message.manager")
local Format = require("noice.text.format")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")

local M = {}

---@param message NoiceMessage
function M.display(message)
  message = Format.format(message, "telescope")
  local line = message._lines[1]
  local hl = {}
  local byte = 0
  for _, text in ipairs(line._texts) do
    local hl_group = text.extmark and text.extmark.hl_group
    if hl_group then
      table.insert(hl, { { byte, byte + text:length() }, hl_group })
    end
    byte = byte + text:length()
  end
  return line:content(), hl
end

function M.finder()
  local messages = Manager.get(Config.options.commands.history.filter, {
    history = true,
    sort = true,
    reverse = true,
  })
  return finders.new_table({
    results = messages,
    entry_maker = function(message)
      return {
        message = message,
        display = function(entry)
          return M.display(entry.message)
        end,
        ordinal = Format.format(message, "telescope"):content(),
      }
    end,
  })
end

function M.previewer()
  return previewers.new_buffer_previewer({
    title = "Message",
    define_preview = function(self, entry, _status)
      vim.api.nvim_win_set_option(self.state.winid, "wrap", true)

      ---@type NoiceMessage
      local message = Format.format(entry.message, "telescope_preview")
      message:render(self.state.bufnr, Config.ns)
    end,
  })
end

function M.telescope(opts)
  pickers
    .new(opts, {
      results_title = "Noice",
      prompt_title = "Filter Noice",
      finder = M.finder(),
      sorter = conf.generic_sorter(opts),
      previewer = M.previewer(),
    })
    :find()
end

return require("telescope").register_extension({
  exports = {
    noice = M.telescope,
  },
})
