local M = {}
M.queries = {}

function M.get_query(lang)
  if not M.queries[lang] then
    ---@diagnostic disable-next-line: deprecated
    M.queries[lang] = (vim.treesitter.query.get or vim.treesitter.query.get_query)(lang, "highlights")
  end
  return M.queries[lang]
end

function M.get_lang(ft)
  return vim.treesitter.language.get_lang and vim.treesitter.language.get_lang(ft) or ft
end

function M.has_lang(lang)
  if vim.treesitter.language.get_lang then
    lang = vim.treesitter.language.get_lang(lang) or lang
    return pcall(vim.treesitter.language.add, lang)
  end
  ---@diagnostic disable-next-line: deprecated
  return vim.treesitter.language.require_language(lang, nil, true)
end

--- Highlights a region of the buffer with a given language
---@param buf integer? buffer to highlight. Defaults to the current buffer if 0
---@param ns number namespace for the highlights
---@param range {[1]:number, [2]:number, [3]: number, [4]: number} (table) Region to highlight {start_row, start_col, end_row, end_col}
---@param lang string treesitter language
-- luacheck: no redefined
function M.highlight(buf, ns, range, lang)
  lang = M.get_lang(lang)

  buf = (buf == 0 or buf == nil) and vim.api.nvim_get_current_buf() or buf

  -- we can't use a cached parser here since that could interfer with the existing parser of the buffer
  local LanguageTree = require("vim.treesitter.languagetree")
  local opts = { injections = { php = "", html = "" } }
  local parser = LanguageTree.new(buf --[[@as integer]], lang, opts)

  ---@diagnostic disable-next-line: invisible
  parser:set_included_regions({ { range } })
  parser:parse(true)

  parser:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end
    local highlighter_query = M.get_query(tree:lang())

    -- Some injected languages may not have highlight queries.
    if not highlighter_query then
      return
    end

    local iter = highlighter_query:iter_captures(tstree:root(), buf, range[1], range[3])

    for capture, node, metadata in iter do
      ---@type number, number, number, number
      local start_row, start_col, end_row, end_col = node:range()

      ---@type string
      local name = highlighter_query.captures[capture]
      local hl = 0
      if not vim.startswith(name, "_") then
        hl = vim.api.nvim_get_hl_id_by_name("@" .. name .. "." .. lang)
      end
      local is_spell = name == "spell"

      if hl and not is_spell then
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, start_row, start_col, {
          end_line = end_row,
          end_col = end_col,
          hl_group = hl,
          priority = (tonumber(metadata.priority) or 100) + 10, -- add 10, so it will be higher than the standard highlighter of the buffer
          conceal = metadata.conceal,
        })
      end
    end
  end)
end

return M
