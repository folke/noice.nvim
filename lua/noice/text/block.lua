local require = require("noice.util.lazy")

local Highlight = require("noice.text.highlight")
local Util = require("noice.util")
local NuiLine = require("nui.line")
local Object = require("nui.object")

---@alias NoiceChunk { [0]: integer, [1]: string}
---@alias NoiceContent string|NoiceChunk|NuiLine|NuiText|NoiceBlock

---@class NoiceBlock
---@field _lines NuiLine[]
---@overload fun(content?: NoiceContent|NoiceContent[], highlight?: string|table): NoiceBlock
local Block = Object("Block")

---@param content? NoiceContent|NoiceContent[]
---@param highlight? string|table data for highlight
function Block:init(content, highlight)
  self._lines = {}
  if content then
    self:append(content, highlight)
  end
end

function Block:clear()
  self._lines = {}
end

function Block:content()
  return table.concat(
    vim.tbl_map(
      ---@param line NuiLine
      function(line)
        return line:content()
      end,
      self._lines
    ),
    "\n"
  )
end

function Block:width()
  local ret = 0
  for _, line in ipairs(self._lines) do
    ret = math.max(ret, line:width())
  end
  return ret
end

function Block:length()
  local ret = 0
  for _, line in ipairs(self._lines) do
    ret = ret + line:width()
  end
  return ret
end

function Block:height()
  return #self._lines
end

function Block:is_empty()
  return #self._lines == 0
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr_start? number line number (1-indexed)
function Block:highlight(bufnr, ns_id, linenr_start)
  self:_fix_extmarks()
  linenr_start = linenr_start or 1
  Highlight.update()
  for _, line in ipairs(self._lines) do
    line:highlight(bufnr, ns_id, linenr_start)
    linenr_start = linenr_start + 1
  end
end

function Block:_fix_extmarks()
  for _, line in ipairs(self._lines) do
    for _, text in ipairs(line._texts) do
      if text.extmark then
        text.extmark.id = nil
      end
    end
  end
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr_start? number start line number (1-indexed)
---@param linenr_end? number end line number (1-indexed)
function Block:render(bufnr, ns_id, linenr_start, linenr_end)
  self:_fix_extmarks()
  linenr_start = linenr_start or 1
  Highlight.update()
  for _, line in ipairs(self._lines) do
    line:render(bufnr, ns_id, linenr_start, linenr_end)
    linenr_start = linenr_start + 1
    if linenr_end then
      linenr_end = linenr_end + 1
    end
  end
end

---@param content string|NuiText|NuiLine
---@param highlight? string|table data for highlight
---@return NuiText|NuiLine
function Block:_append(content, highlight)
  if #self._lines == 0 then
    table.insert(self._lines, NuiLine())
  end
  if type(content) == "string" and true then
    -- handle carriage returns. They overwrite the line from the first character
    local cr = content:match("^.*()[\r]")
    if cr then
      table.remove(self._lines)
      table.insert(self._lines, NuiLine())
      content = content:sub(cr + 1)
    end
  end
  return self._lines[#self._lines]:append(content, highlight)
end

---@param contents NoiceContent|NoiceContent[]
---@param highlight? string|table data for highlight
function Block:set(contents, highlight)
  self:clear()
  self:append(contents, highlight)
end

---@param contents NoiceContent|NoiceContent[]
---@param highlight? string|table data for highlight
function Block:append(contents, highlight)
  if type(contents) == "string" then
    contents = { { highlight or 0, contents } }
  end

  if contents._texts or contents._content or contents._lines or type(contents[1]) == "number" then
    contents = { contents }
  end

  ---@cast contents NoiceContent[]
  for _, content in ipairs(contents) do
    if content._texts then
      ---@cast content NuiLine
      for _, t in ipairs(content._texts) do
        self:_append(t)
      end
    elseif content._content then
      ---@cast content NuiText
      self:_append(content)
    elseif content._lines then
      ---@cast content NoiceBlock
      for l, line in ipairs(content._lines) do
        if l == 1 then
          -- first line should be appended to the existing line
          self:append(line)
        else
          -- other lines are appened as new lines
          table.insert(self._lines, line)
        end
      end
    else
      ---@cast content NoiceChunk
      -- Handle newlines
      ---@type number|string|table, string
      local attr_id, text = unpack(content)
      -- msg_show messages can contain invalid \r characters
      text = text:gsub("%^M", "\r")
      text = text:gsub("\r\n", "\n")

      ---@type string|table|nil
      local hl_group
      if type(attr_id) == "number" then
        hl_group = attr_id ~= 0 and Highlight.get_hl_group(attr_id) or nil
      else
        hl_group = attr_id
      end

      while text ~= "" do
        local nl = text:find("\n")
        local line = nl and text:sub(1, nl - 1) or text
        self:_append(line, hl_group)
        if nl then
          self:newline()
          text = text:sub(nl + 1)
        else
          break
        end
      end
    end
  end
end

function Block:last_line()
  return self._lines[#self._lines]
end

-- trim empty lines at the beginning and the end of the block
function Block:trim_empty_lines()
  while #self._lines > 0 and vim.trim(self._lines[1]:content()) == "" do
    table.remove(self._lines, 1)
  end
  while #self._lines > 0 and vim.trim(self._lines[#self._lines]:content()) == "" do
    table.remove(self._lines)
  end
end

function Block:newline()
  table.insert(self._lines, NuiLine())
end

return Block
