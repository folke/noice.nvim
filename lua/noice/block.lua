local Highlight = require("noice.highlight")
local NuiLine = require("nui.line")
local Object = require("nui.object")
local NuiText = require("nui.text")

---@class NoiceHighlight
---@field line integer 1-indexed
---@field hl_group string
---@field col integer
---@field end_col integer

---@alias NoiceChunk { [0]: integer, [1]: string}
---@alias NoiceContent string|NoiceChunk|NuiLine|NuiText|NoiceHighlight

---@class NoiceBlock
---@field private _lines NuiLine[]
---@field private _attr_ids table<number, number>
---@field private _highlights NoiceHighlight[]
local Block = Object("Block")

---@param content NoiceContent|NoiceContent[]
---@param highlight? string|table data for highlight
function Block:init(content, highlight)
  self._lines = {}
  self._highlights = {}
  self._attr_ids = {}
  if content then
    self:append(content, highlight)
  end
end

function Block:clear()
  self._lines = {}
  self._highlights = {}
  self._attr_ids = {}
end

function Block:content()
  return table.concat(
    vim.tbl_map(function(line)
      ---@cast line NuiLine
      return line:content()
    end, self._lines),
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
  linenr_start = linenr_start or 1
  local start = linenr_start
  self:_create_attr_hl_groups()
  for _, line in ipairs(self._lines) do
    line:highlight(bufnr, ns_id, linenr_start)
    linenr_start = linenr_start + 1
  end
  self:_apply_highlights(bufnr, ns_id, start)
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr_start? number start line number (1-indexed)
---@param linenr_end? number end line number (1-indexed)
function Block:render(bufnr, ns_id, linenr_start, linenr_end)
  linenr_start = linenr_start or 1
  local start = linenr_start
  self:_create_attr_hl_groups()
  for _, line in ipairs(self._lines) do
    line:render(bufnr, ns_id, linenr_start, linenr_end)
    linenr_start = linenr_start + 1
    if linenr_end then
      linenr_end = linenr_end + 1
    end
  end
  self:_apply_highlights(bufnr, ns_id, start)
end

function Block:_create_attr_hl_groups()
  for _, attr_id in pairs(self._attr_ids) do
    Highlight.get_hl(attr_id)
  end
  self._attr_ids = {}
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr_start number start line number (1-indexed)
function Block:_apply_highlights(bufnr, ns_id, linenr_start)
  for _, hl in ipairs(self._highlights) do
    local line_width = self._lines[hl.line]:width()
    if hl.col >= line_width then
      -- end of line, so use a virtual text
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, hl.line + linenr_start - 2, 0, {
        virt_text = { { " ", hl.hl_group } },
        virt_text_win_col = hl.col,
        -- strict = false,
      })
    else
      -- use a regular extmark
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, hl.line + linenr_start - 2, hl.col, {
        end_col = hl.end_col,
        hl_group = hl.hl_group,
        -- strict = false,
      })
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
    contents = NuiText(contents, highlight)
  end

  if contents._texts or contents._content or type(contents[1]) == "number" or contents.hl_group then
    contents = { contents }
  end

  ---@cast contents NoiceContent[]
  for _, content in ipairs(contents) do
    if content._texts then
      ---@cast content NuiLine
      table.insert(self._lines, content)
    elseif content._content then
      ---@cast content NuiText
      self:_append(content)
    elseif content.hl_group then
      ---@cast content NoiceHighlight
      table.insert(self._highlights, content)
    else
      ---@cast content NoiceChunk
      -- Handle newlines
      local attr_id, text = unpack(content)
      text = text:gsub("\r", "")
      self._attr_ids[attr_id] = attr_id
      local hl_group = Highlight.get_hl_group(attr_id)
      while text ~= "" do
        local nl = text:find("\n")
        if nl then
          local str = text:sub(1, nl - 1)
          self:_append(str, hl_group)
          self:newline()
          text = text:sub(nl + 1)
        else
          self:_append(text, hl_group)
          break
        end
      end
    end
  end
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

---@alias NoiceBlock.constructor fun(content: NoiceContent|NoiceContent[], highlight?: string|table): NoiceBlock
---@type NoiceBlock|NoiceBlock.constructor
local NoiceBlock = Block

return NoiceBlock
