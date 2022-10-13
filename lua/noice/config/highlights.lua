local require = require("noice.util.lazy")

local Util = require("noice.util")

local M = {}

M.defaults = {
  Cmdline = "MsgArea", -- Normal for the classic cmdline area at the bottom"
  CmdlinePopup = "Normal", -- Normal for the cmdline popup
  CmdlinePopupBorder = "DiagnosticSignInfo", -- Cmdline popup border
  CmdlinePopupSearchBorder = "DiagnosticSignWarn", -- Cmdline popup border for search
  Confirm = "Normal", -- Normal for the confirm view
  ConfirmBorder = "DiagnosticSignInfo", -- Border for the confirm view
  Mini = "MsgArea", -- Normal for mini view
  Popup = "NormalFloat", -- Normal for popup views
  PopupBorder = "FloatBorder", -- Border for popup views
  Popupmenu = "Pmenu", -- Normal for the popupmenu
  PopupmenuBorder = "FloatBorder", -- Popupmenu border
  PopupmenuMatch = "Special", -- Part of the item that matches the input
  PopupmenuSelected = "PmenuSel", -- Selected item in the popupmenu
  Scrollbar = "PmenuSbar", -- Normal for scrollbar
  ScrollbarThumb = "PmenuThumb", -- Scrollbar thumb
  Split = "NormalFloat", -- Normal for split views
  SplitBorder = "FloatBorder", -- Border for split views
  VirtualText = "DiagnosticVirtualTextInfo", -- Default hl group for virtualtext views
}

function M.setup()
  for hl, link in pairs(M.defaults) do
    vim.api.nvim_set_hl(0, "Noice" .. hl, { link = link, default = true })
  end
end

function M.docs()
  local me = debug.getinfo(1, "S").source:sub(2)
  ---@type table<string,string>
  local docs = {}
  local lines = io.open(me, "r"):lines()
  for line in lines do
    ---@type string, string
    local hl, comment = line:match("%s*([a-zA-Z]+)%s*=.*%-%-%s*(.*)")
    if hl then
      docs[hl] = comment
    end
  end

  local rows = {}
  table.insert(rows, { "Highlight Group", "Default Group", "Description" })
  table.insert(rows, { "---", "---", "---" })

  Util.for_each(M.defaults, function(hl, link)
    table.insert(rows, { "**Noice" .. hl .. "**", "*" .. link .. "*", docs[hl] or "" })
  end)

  local text = table.concat(
    vim.tbl_map(function(row)
      return "| " .. table.concat(row, " | ") .. " |"
    end, rows),
    "\n"
  )

  text = "<!-- hl_start -->\n" .. text .. "\n<!-- hl_end -->"

  local readme = Util.read_file("README.md")
  readme = readme:gsub("<%!%-%- hl_start %-%->.*<%!%-%- hl_end %-%->", text)
  Util.write_file("README.md", readme)
end

return M
