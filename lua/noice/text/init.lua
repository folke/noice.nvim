local require = require("noice.util.lazy")

local NuiText = require("nui.text")
local Treesitter = require("noice.text.treesitter")
local Syntax = require("noice.text.syntax")
local Markdown = require("noice.text.markdown")

---@class NoiceExtmark
---@field col? number
---@field end_col? number
---@field id? number
---@field hl_group? string
---@field virt_self_win_col? number
---@field relative? boolean
---@field lang? string
---@field lines? number

---@class NoiceText: NuiText
---@field super NuiText
---@field on_render? fun(text: NoiceText, buf:number, line: number, byte:number, col:number)
---@overload fun(content:string, highlight?:string|NoiceExtmark):NoiceText
---@diagnostic disable-next-line: undefined-field
local NoiceText = NuiText:extend("NoiceText")

function NoiceText.virtual_text(text, hl_group)
  local content = (" "):rep(vim.api.nvim_strwidth(text))
  return NoiceText(content, {
    virt_text = { { text, hl_group } },
    virt_text_win_col = 0,
    relative = true,
  })
end

function NoiceText.cursor(col)
  return NoiceText(" ", {
    hl_group = "NoiceCursor",
    col = col,
    relative = true,
  })
end

---@param col? number
function NoiceText.syntax(lang, lines, col)
  return NoiceText("", {
    lang = lang,
    col = col,
    lines = lines,
  })
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr number line number (1-indexed)
---@param byte_start number start byte position (0-indexed)
---@return nil
function NoiceText:highlight(bufnr, ns_id, linenr, byte_start)
  if not self.extmark then
    return
  end

  if self.extmark.lang then
    local range = { linenr - self.extmark.lines, 0, linenr, byte_start + 1 }
    if self.extmark.col then
      range[2] = byte_start + self.extmark.col - 1
    end
    if Treesitter.has_lang(self.extmark.lang) then
      Treesitter.highlight(bufnr, ns_id, range, self.extmark.lang)
    else
      Syntax.highlight(bufnr, ns_id, range, self.extmark.lang)
    end
    if self.extmark.lang == "markdown" then
      Markdown.keys(bufnr)
      Markdown.conceal_escape_characters(bufnr, ns_id, range)
    end
    return
  end

  local byte_start_orig = byte_start

  ---@type NoiceExtmark
  local orig = vim.deepcopy(self.extmark)
  local extmark = self.extmark

  local col_start = 0

  if extmark.relative or self.on_render then
    ---@type string
    local line = vim.api.nvim_buf_get_text(bufnr, linenr - 1, 0, linenr - 1, byte_start, {})[1]
    col_start = vim.api.nvim_strwidth(line)
  end

  if extmark.relative then
    if extmark.virt_text_win_col then
      extmark.virt_text_win_col = extmark.virt_text_win_col + col_start
    end
    if extmark.col then
      extmark.col = extmark.col + byte_start
    end
    extmark.relative = nil
  end

  local length = self._length
  if extmark.length then
    self._length = extmark.length
    extmark.length = nil
  end

  if extmark.col then
    ---@type number
    byte_start = extmark.col
    extmark.col = nil
  end

  NoiceText.super.highlight(self, bufnr, ns_id, linenr, byte_start)

  if self.on_render then
    self.on_render(self, bufnr, linenr, byte_start_orig, col_start)
  end

  self._length = length
  self.extmark = orig
end

return NoiceText
