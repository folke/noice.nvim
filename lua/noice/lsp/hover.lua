local require = require("noice.util.lazy")

local Config = require("noice.config")
local Docs = require("noice.lsp.docs")
local Format = require("noice.lsp.format")
local Util = require("noice.util")

local M = {}

---@param results table<integer,{result?:lsp.Hover}>
---@param ctx {bufnr:integer}
function M.on_hover(results, ctx)
  ---@type integer[]
  local client_ids = {}
  for client_id, resp in pairs(results) do
    if resp.result and resp.result.contents then
      client_ids[#client_ids + 1] = client_id
    end
  end
  table.sort(client_ids)

  if #client_ids == 0 then
    if Config.options.lsp.hover.silent ~= true then
      vim.notify("No information available")
    end
    return
  end

  local message = Docs.get("hover")

  if message:focus() then
    return
  end

  local ft = vim.bo[ctx.bufnr].filetype
  for i, client_id in ipairs(client_ids) do
    if i > 1 then
      Format.format(message, "---", { ft = ft })
    end
    -- markdown_inline has no headings, so highlight the client name instead
    if #client_ids > 1 then
      local client = vim.lsp.get_client_by_id(client_id)
      message:newline()
      message:append(client and client.name or tostring(client_id), "@markup.heading")
      message:newline()
    end
    Format.format(message, results[client_id].result.contents, { ft = ft })
  end

  if message:is_empty() then
    if Config.options.lsp.hover.silent ~= true then
      vim.notify("No information available")
    end
    return
  end
  Docs.show(message)
end
M.on_hover = Util.protect(M.on_hover)

return M
