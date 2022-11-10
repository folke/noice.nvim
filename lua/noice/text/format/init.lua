local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")
local FormatConfig = require("noice.config.format")
local Formatters = require("noice.text.format.formatters")
local NuiText = require("nui.text")

local M = {}

---@alias NoiceFormatter fun(message:NoiceMessage, opts: table, input: NoiceMessage): boolean
---@alias NoiceFormat (string|table)[]

---@class NoiceFormatEntry
---@field formatter string
---@field before? NoiceFormatEntry
---@field after? NoiceFormatEntry
---@field opts table

---@param entry string|table<string, any>
---@return NoiceFormatEntry?
function M.parse_entry(entry)
  if type(entry) == "string" then
    entry = { entry }
  end

  if #entry ~= 1 then
    Util.panic("Invalid format entry %s", vim.inspect(entry))
    return
  end

  local text = entry[1]

  ---@type NoiceFormatEntry
  local ret = {
    formatter = "text",
    opts = { text = text },
  }

  local before, name, after = text:match("^(.*){(.-)}(.*)$")
  if before then
    ret.formatter = name
    ret.before = M.parse_entry(before)
    ret.after = M.parse_entry(after)
  end

  local opts_key = ret.formatter:match("^data%.(.*)")
  if opts_key then
    entry.key = opts_key
    ret.formatter = "data"
  end

  if not Formatters[ret.formatter] then
    Util.panic("Invalid formatter %s", ret.formatter)
    return
  end

  for k, v in pairs(entry) do
    if k == "before" then
      ret.before = M.parse_entry(v)
    elseif k == "after" then
      ret.after = M.parse_entry(v)
    elseif type(k) ~= "number" then
      ---@diagnostic disable-next-line: no-unknown
      ret.opts[k] = v
    end
  end

  return ret
end

---@param message NoiceMessage
---@param format? NoiceFormat|string
---@param opts? NoiceFormatOptions
---@return NoiceMessage
function M.format(message, format, opts)
  opts = vim.tbl_deep_extend("force", vim.deepcopy(Config.options.format), opts or {})

  format = format or "default"

  if type(format) == "string" then
    format = vim.deepcopy(FormatConfig.builtin[format])
  end

  -- use existing message, with a separate _lines array
  local ret = setmetatable({ _lines = {}, _debug = false }, { __index = message })
  if Config.options.debug and not message._debug then
    table.insert(format, 1, "{debug}")
    ret._debug = true
  end

  for _, entry in ipairs(format) do
    entry = M.parse_entry(entry)
    if entry then
      entry.opts = vim.tbl_deep_extend("force", vim.deepcopy(opts[entry.formatter] or {}), entry.opts)

      local formatted = setmetatable({ _lines = {} }, { __index = message })
      Formatters[entry.formatter](formatted, entry.opts, message)

      if not formatted:is_empty() then
        if entry.before then
          Formatters[entry.before.formatter](ret, entry.before.opts, message)
        end

        ret:append(formatted)

        if entry.after then
          -- Else, add after
          Formatters[entry.after.formatter](ret, entry.after.opts, message)
        end
      end
    end
  end

  return ret
end

---@alias NoiceAlign "center" | "left" | "right" | "message-center" | "message-left" | "message-right" | "line-center" | "line-left" | "line-right"

---@param messages NoiceMessage[]
---@param align? NoiceAlign
function M.align(messages, align)
  local width = 0
  for _, m in ipairs(messages) do
    for _, line in ipairs(m._lines) do
      ---@diagnostic disable-next-line: undefined-field
      if line._texts[1] and line._texts[1].padding then
        table.remove(line._texts, 1)
      end
    end
    width = math.max(width, m:width())
  end

  for _, m in ipairs(messages) do
    M._align(m, width, align)
  end
end

---@param message NoiceMessage
---@param width integer
---@param align? NoiceAlign
function M._align(message, width, align)
  if align == nil or align == "left" then
    return
  end

  local align_object = "message"

  ---@type string, string
  local ao, a = align:match("^(.-)%-(.-)$")
  if a then
    align = a
    align_object = ao
  end

  for _, line in ipairs(message._lines) do
    local w = align_object == "line" and line:width() or message:width()
    if w < width then
      if align == "right" then
        table.insert(line._texts, 1, NuiText(string.rep(" ", width - w)))
        ---@diagnostic disable-next-line: no-unknown
        line._texts[1].padding = true
      elseif align == "center" then
        table.insert(line._texts, 1, NuiText(string.rep(" ", math.floor((width - w) / 2 + 0.5))))
        ---@diagnostic disable-next-line: no-unknown
        line._texts[1].padding = true
      end
    end
  end
end

return M
