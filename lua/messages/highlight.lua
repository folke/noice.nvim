---@diagnostic disable: undefined-global
local M = {}

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
	if not ok and not err:find("redefine") then
		error(err)
	end
	M.attr2entry = ffi.C.syn_attr2entry
end

function M.attr2entry(attr_id)
	M.setup()
	return M.attr2entry(attr_id)
end

M.cache = {}

function M.get_hl(attr_id)
	if not M.cache[attr_id] then
		local attrs = M.attr2entry(attr_id)
		local hl_group = "MessagesAttr" .. tostring(attr_id)
		vim.api.nvim_set_hl(0, hl_group, {
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
		})
		M.cache[attr_id] = hl_group
	end
	return M.cache[attr_id]
end

return M
