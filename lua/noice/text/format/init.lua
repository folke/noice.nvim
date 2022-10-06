local require = require("noice.util.lazy")

local Util = require("noice.util")
local Config = require("noice.config")
local Formatters = require("noice.text.format.formatters")

local M = {}

---@alias NoiceFormatter fun(message:NoiceMessage, opts: table, input: NoiceMessage): boolean
---@alias NoiceFormat (string|table)[]

---@class NoiceFormatEntry
---@field formatter string
---@field before? NoiceFormatEntry
---@field after? NoiceFormatEntry
---@field opts table

M.format = { "level", "debug", "message" }
M.format = { { "level" }, "debug", "message" }

M.formats = {
  default = { "{level} ", "{title} ", "{message}" },
  notify = { "{message}" },
  details = {
    "{level} ",
    "{date} ",
    "{event}",
    { "{kind}", before = { ".", hl_group = "Comment" } },
    " ",
    "{title} ",
    "{message}",
  },
}

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

  local before, name, after = text:match("^(.*){(.*)}(.*)$")
  if before then
    ret.formatter = name
    ret.before = M.parse_entry(before)
    ret.after = M.parse_entry(after)
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
---@param format? NoiceFormat
---@param opts? NoiceFormatOptions
---@return NoiceMessage
function M.format(message, format, opts)
  opts = vim.tbl_deep_extend("force", Config.options.format, opts or {})

  format = format or "default"

  if type(format) == "string" then
    format = vim.deepcopy(M.formats[format])
  end

  if Config.options.debug then
    table.insert(format, 1, "{debug}")
  end

  -- use existing message, with a separate _lines array
  local ret = setmetatable({ _lines = {} }, { __index = message })

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

return M
