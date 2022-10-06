local M = {}

---@class NoiceFormatOptions
M.defaults = {
  ---@class NoiceFormatOptions.debug
  debug = {},
  ---@class NoiceFormatOptions.level
  level = {
    hl_group = {
      debug = "Comment",
      trace = "Comment",
      off = "Comment",
      error = "DiagnosticVirtualTextError",
      warn = "DiagnosticVirtualTextWarn",
      info = "DiagnosticVirtualTextInfo",
    },
    icons = { error = " ", warn = " ", info = " " },
  },
  ---@class NoiceFormatOptions.text
  text = {
    text = nil,
    hl_group = nil,
  },
  ---@class NoiceFormatOptions.title
  title = {
    hl_group = "Identifier",
  },
  ---@class NoiceFormatOptions.event
  event = {
    hl_group = "Comment",
  },
  ---@class NoiceFormatOptions.kind
  kind = {
    hl_group = "Comment",
  },
  ---@class NoiceFormatOptions.date
  date = {
    format = "%c", --- @see https://www.lua.org/pil/22.1.html
    hl_group = "Special",
  },
  ---@class NoiceFormatOptions.message
  message = {
    hl_group = nil,
  },
}

return M
