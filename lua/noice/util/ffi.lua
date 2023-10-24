local M = {}

---@return ffi.namespace*
function M.load()
  -- Put in a global var to make sure we dont reload
  -- when plugin reloaders do their thing
  if not _G.noice_C then
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
      bool cmdpreview;
      void setcursor_mayforce(bool force);
    ]]
    )
    ---@diagnostic disable-next-line: need-check-nil
    if not ok then
      error(err)
    end
    _G.noice_C = ffi.C
  end
  return _G.noice_C
end

return setmetatable(M, {
  __index = function(_, key)
    -- HACK: cmdpreview symbol is not available on Windows
    if key == "cmdpreview" and jit.os == "Windows" then
      return false
    end
    return M.load()[key]
  end,
  __newindex = function(_, k, v)
    M.load()[k] = v
  end,
})
