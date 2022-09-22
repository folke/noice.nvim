local Highlight = require("noice.highlight")
local NuiLine = require("nui.line")
local NuiText = require("nui.text")

---@alias noice.Chunk { [0]: integer, [1]: string}
---@alias noice.Highlight { line: integer, hl_group: string, col: integer, end_col: integer }

---@class noice.Message
---@field _lines NuiLine[]
---@field _attr_ids table<number, number>
---@field _highlights noice.Highlight[]
local Message = {}
Message.__index = Message

function Message:clear()
  self._lines = {}
  self._highlights = {}
  self._attr_ids = {}
end

function Message:content()
  return table.concat(
    vim.tbl_map(function(line)
      ---@cast line NuiLine
      return line:content()
    end, self._lines),
    "\n"
  )
end

function Message:width()
  local ret = 0
  for _, line in ipairs(self._lines) do
    ret = math.max(ret, line:width())
  end
  return ret
end

function Message:height()
  return #self._lines
end

---@param bufnr number buffer number
---@param linenr_start? number line number (1-indexed)
---@return nil
function Message:highlight(bufnr, ns_id, linenr_start)
  linenr_start = linenr_start or 0
  self:_create_attr_hl_groups()
  for l, line in ipairs(self._lines) do
    line:highlight(bufnr, ns_id, l + linenr_start)
  end
  self:_apply_highlights(bufnr, ns_id, linenr_start)
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr_start? number start line number (1-indexed)
---@param linenr_end? number end line number (1-indexed)
---@return nil
function Message:render(bufnr, ns_id, linenr_start, linenr_end)
  linenr_start = linenr_start or 0
  self:_create_attr_hl_groups()
  for l, line in ipairs(self._lines) do
    line:render(bufnr, ns_id, l + linenr_start, linenr_end and (l + linenr_end) or nil)
  end
  self:_apply_highlights(bufnr, ns_id, linenr_start)
end

function Message:_create_attr_hl_groups()
  for _, attr_id in pairs(self._attr_ids) do
    Highlight.get_hl(attr_id)
  end
  self._attr_ids = {}
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr_start number start line number (1-indexed)
function Message:_apply_highlights(bufnr, ns_id, linenr_start)
  for _, hl in ipairs(self._highlights) do
    local line_width = self._lines[hl.line + 1]:width()
    if hl.col >= line_width then
      -- end of line, so use a virtual text
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, hl.line + linenr_start, hl.col, {
        virt_text = { { " ", hl.hl_group } },
        virt_text_win_col = hl.col,
      })
    else
      -- use a regular extmark
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, hl.line + linenr_start, hl.col, {
        end_col = hl.end_col,
        hl_group = hl.hl_group,
      })
    end
  end
end

---@param content string|NuiText|NuiLine
---@param highlight? string|table data for highlight
---@return NuiText|NuiLine
function Message:_append(content, highlight)
  if #self._lines == 0 then
    table.insert(self._lines, NuiLine())
  end
  return self._lines[#self._lines]:append(content, highlight)
end

---@param contents string|noice.Chunk|NuiLine|NuiText|(noice.Chunk|NuiLine|NuiText)[]
---@param highlight? string|table data for highlight
function Message:set(contents, highlight)
  self:clear()
  self:append(contents, highlight)
end

---@param contents string|noice.Chunk|NuiLine|NuiText|noice.Highlight|(noice.Chunk|NuiLine|NuiText|noice.Highlight)[]
---@param highlight? string|table data for highlight
function Message:append(contents, highlight)
  if type(contents) == "string" then
    contents = NuiText(contents, highlight)
  end

  if contents._texts or contents._content or type(contents[1]) == "number" or contents.hl_group then
    contents = { contents }
  end

  ---@cast contents (noice.Chunk|NuiLine|NuiText|noice.Highlight)[]
  for _, content in ipairs(contents) do
    if content._texts then
      ---@cast content NuiLine
      table.insert(self._lines, content)
    elseif content._content then
      ---@cast content NuiText
      self:_append(content)
    elseif content.hl_group then
      ---@cast content noice.Highlight
      table.insert(self._highlights, content)
    else
      ---@cast content noice.Chunk
      -- Handle newlines
      local attr_id, text = unpack(content)
      self._attr_ids[attr_id] = attr_id
      local hl_group = Highlight.get_hl_group(attr_id)
      while text ~= "" do
        local nl = text:find("\n")
        if nl then
          local str = text:sub(1, nl - 1)
          self:_append(str, hl_group)
          table.insert(self._lines, NuiLine())
          text = text:sub(nl + 1)
        else
          self:_append(text, hl_group)
          break
        end
      end
    end
  end
end

return function()
  return setmetatable({
    _lines = {},
    _highlights = {},
    _attr_ids = {},
  }, Message)
end
