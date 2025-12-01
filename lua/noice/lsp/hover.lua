local require = require("noice.util.lazy")

local Config = require("noice.config")
local Docs = require("noice.lsp.docs")
local Format = require("noice.lsp.format")
local Util = require("noice.util")

local M = {}

---@type lsp.MultiHandler
function M.on_hover(results, ctx)
  local bufnr = assert(ctx.bufnr)
  if vim.api.nvim_get_current_buf() ~= bufnr then
    -- Ignore result since buffer changed. This happens for slow language servers.
    return
  end

  -- Filter errors from results
  local results1 = {} --- @type table<integer,lsp.Hover>

  for client_id, resp in pairs(results) do
    local err, result = resp.err, resp.result
    if err then
      vim.lsp.log.error(err.code, err.message)
    elseif result and result.contents then
      -- Make sure the response is not empty
      -- Five response shapes:
      -- - MarkupContent: { kind="markdown", value="doc" }
      -- - MarkedString-string: "doc"
      -- - MarkedString-pair: { language="c", value="doc" }
      -- - MarkedString[]-string: { "doc1", ... }
      -- - MarkedString[]-pair: { { language="c", value="doc1" }, ... }
      if
        (
          type(result.contents) == "table"
          and #(
              vim.tbl_get(result.contents, "value") -- MarkupContent or MarkedString-pair
              or vim.tbl_get(result.contents, 1, "value") -- MarkedString[]-pair
              or result.contents[1] -- MarkedString[]-string
              or ""
            )
            > 0
        )
        or (
          type(result.contents) == "string" and #result.contents > 0 -- MarkedString-string
        )
      then
        results1[client_id] = result
      end
    end
  end

  if vim.tbl_isempty(results1) then
    if Config.options.lsp.hover.silent ~= true then
      vim.notify("No information available")
    end
    return
  end

  local contents = {} --- @type MarkupContents[]

  -- local nresults = #vim.tbl_keys(results1)

  for _client_id, result in pairs(results1) do
    contents[#contents + 1] = result.contents
    contents[#contents + 1] = "---"
  end

  -- Remove last linebreak ('---')
  contents[#contents] = nil

  local message = Docs.get("hover")

  if not message:focus() then
    Format.format(message, contents, { ft = vim.bo[ctx.bufnr].filetype })
    if message:is_empty() then
      if Config.options.lsp.hover.silent ~= true then
        vim.notify("No information available")
      end
      return
    end
    Docs.show(message)
  end
end
M.on_hover = Util.protect(M.on_hover)

return M
