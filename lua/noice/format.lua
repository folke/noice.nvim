local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")
local NoiceText = require("noice.text")

local M = {}

---@param message NoiceMessage
---@return NoiceMessage
function M.format(message)
  -- use existing message, with a separate _lines array
  local ret = setmetatable({ _lines = {} }, { __index = message })

  if Config.options.debug then
    M.format_debug(ret)
  end

  ret:append(message)

  return ret
end

---@param message NoiceMessage
function M.format_debug(message)
  local blocking, reason = Util.is_blocking()
  local debug = {
    message:is({ cleared = true }) and "" or "",
    "#" .. message.id,
    message.event .. (message.kind and message.kind ~= "" and ("." .. message.kind) or ""),
    blocking and "⚡ " .. reason,
  }
  message:append(NoiceText.virtual_text(
    table.concat(
      vim.tbl_filter(
        ---@param t string
        function(t)
          return t
        end,
        debug
      ),
      " "
    ),
    "DiagnosticVirtualTextInfo"
  ))
  if message.event == "cmdline" then
    message:newline()
  else
    message:append(" ")
  end
end

return M
