local require = require("noice.util.lazy")

local Config = require("noice.config")
local Highlights = require("noice.config.highlights")

local M = {}

function M.setup()
  local formats = Config.options.cmdline.format
  for name, format in pairs(formats) do
    if format == false then
      formats[name] = nil
    else
      local kind = format.kind or name
      local kind_cc = kind:sub(1, 1):upper() .. kind:sub(2)

      local hl_group_icon = "CmdlineIcon" .. kind_cc
      Highlights.add(hl_group_icon, "NoiceCmdlineIcon")

      local hl_group_border = "CmdlinePopupBorder" .. kind_cc
      Highlights.add(hl_group_border, "NoiceCmdlinePopupBorder")

      local hl_group_title = "CmdlinePopupTitle" .. kind_cc
      Highlights.add(hl_group_title, "Noice" .. hl_group_border)

      format = vim.tbl_deep_extend("force", {
        name = name,
        conceal = format.conceal ~= false,
        kind = name,
        icon_hl_group = "Noice" .. hl_group_icon,
        view = Config.options.cmdline.view,
        lang = format.lang or format.ft,
        opts = {
          ---@diagnostic disable-next-line: undefined-field
          border = {
            text = {
              top = format.title or (" " .. kind_cc .. " "),
            },
          },
          win_options = {
            winhighlight = {
              FloatBorder = "Noice" .. hl_group_border,
              FloatTitle = "Noice" .. hl_group_title,
            },
          },
        },
      }, { opts = vim.deepcopy(Config.options.cmdline.opts) }, format)
      formats[name] = format

      table.insert(Config.options.routes, {
        view = format.view,
        opts = format.opts,
        filter = { event = "cmdline", kind = name },
      })
    end
  end
end

return M
