local M = {}

---@type ffi.namespace*
local C = nil

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
      HlAttrs syn_attr2entry(int attr);
      void update_screen();
    ]]
  )
  if not ok then
    error(err)
  end
  C = ffi.C
end

return setmetatable(M, {
  __index = function(_, key)
    if not C then
      M.setup()
    end
    return C[key]
  end,
  __newindex = function(_, k, v)
    if not C then
      M.setup()
    end
    C[k] = v
  end,
})
