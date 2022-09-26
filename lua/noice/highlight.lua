---@diagnostic disable: undefined-global
local M = {}

---@class HLAttrs
---@field rgb_ae_attr number
---@field rgb_fg_color number
---@field rgb_bg_color number
---@field rgb_sp_color number
---@field hl_blend number

function M.setup()
  local ffi = require("ffi")
  local ok, err = pcall(
    ffi.cdef,
    [[typedef int32_t RgbValue;
      typedef struct attr_entry {
        int16_t rgb_ae_attr, cterm_ae_attr;
        RgbValue rgb_fg_color, rgb_bg_color, rgb_sp_color;
        int cterm_fg_color, cterm_bg_color;
        int hl_blend;
      } HlAttrs;
      HlAttrs syn_attr2entry(int attr);]]
  )
  ---@diagnostic disable-next-line: need-check-nil
  if not ok and not err:find("redefine") then
    error(err)
  end
  M.attr2entry = ffi.C.syn_attr2entry --[[@as fun(attr: number): HLAttrs]]

  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
      M.hl = {}
      for attr_id, _ in pairs(M.hl_attrs) do
        M._create_hl(attr_id)
      end
    end,
  })
end

---@param attr_id number
function M.attr2entry(attr_id)
  M.setup()
  return M.attr2entry(attr_id)
end

---@type table<number, number>
M.hl = {}

---@type table<string, table>
M.hl_attrs = {}

---@type table<number, number>
M.queue = {}

function M.get_hl_group(attr_id)
  M.queue[attr_id] = attr_id
  return "NoiceAttr" .. tostring(attr_id)
end

function M.update()
  for attr_id, _ in pairs(M.queue) do
    M._create_hl(attr_id)
  end
  M.queue = {}
end

function M._create_hl(attr_id)
  if not M.hl_attrs[attr_id] then
    local attrs = M.attr2entry(attr_id)
    M.hl_attrs[attr_id] = {
      fg = attrs.rgb_fg_color,
      bg = attrs.rgb_bg_color,
      sp = attrs.rgb_sp_color,
      bold = bit.band(attrs.rgb_ae_attr, 0x02),
      standout = bit.band(attrs.rgb_ae_attr, 0x0100),
      italic = bit.band(attrs.rgb_ae_attr, 0x04),
      underline = bit.band(attrs.rgb_ae_attr, 0x08),
      undercurl = bit.band(attrs.rgb_ae_attr, 0x10),
      nocombine = bit.band(attrs.rgb_ae_attr, 0x0200),
      reverse = bit.band(attrs.rgb_ae_attr, 0x01),
      blend = attrs.hl_blend ~= -1 and attrs.hl_blend or nil,
    }
  end
  if not M.hl[attr_id] then
    local hl_group = M.get_hl_group(attr_id)
    vim.api.nvim_set_hl(0, hl_group, M.hl_attrs[attr_id])
    M.hl[attr_id] = attr_id
  end
end

return M
