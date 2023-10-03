---@class NuiRelative
---@field type "'cursor'"|"'editor'"|"'win'"
---@field winid? number
---@field position? { row: number, col: number }

---@alias _.NuiBorderStyle "'double'"|"'none'"|"'rounded'"|"'shadow'"|"'single'"|"'solid'"

---@alias _.NuiBorderPadding {top:number, right:number, bottom:number, left:number}

---@class _.NuiBorder
---@field padding? _.NuiBorderPadding
---@field style? _.NuiBorderStyle
---@field text? { top: string|boolean, bottom: string|boolean }

---@class NuiBorder: _.NuiBorder
---@field padding? _.NuiBorderPadding|number[]

---@class _.NuiBaseOptions
---@field relative? NuiRelative
---@field enter? boolean
---@field timeout? number
---@field buf_options? vim.bo
---@field win_options? vim.wo
---@field close? {events?:string[], keys?:string[]}

---@class NuiBaseOptions: _.NuiBaseOptions
---@field relative "'cursor'"|"'editor'"|"'win'"|NuiRelative

---@alias NuiAnchor "NW"|"NE"|"SW"|"SE"

---@class _.NuiPopupOptions: _.NuiBaseOptions
---@field position { row: number|string, col: number|string}
---@field size { width: number|string, height: number|string, max_width:number, max_height:number}
---@field border? _.NuiBorder
---@field anchor? NuiAnchor|"auto"
---@field focusable boolean
---@field zindex? number

---@class NuiPopupOptions: NuiBaseOptions,_.NuiPopupOptions
---@field position number|string|{ row: number|string, col: number|string}
---@field size number|string|{ row: number|string, col: number|string}
---@field border? NuiBorder|_.NuiBorderStyle

---@class _.NuiSplitOptions: _.NuiBaseOptions
---@field position "top"|"right"|"bottom"|"left"
---@field scrollbar? boolean
---@field min_size? number
---@field max_size? number
---@field size number|string

---@class NuiSplitOptions: NuiBaseOptions,_.NuiSplitOptions

---@alias NoiceNuiOptions NuiSplitOptions|NuiPopupOptions|{type: "split"|"popup"}
---@alias _.NoiceNuiOptions _.NuiSplitOptions|_.NuiPopupOptions|{type: "split"|"popup"}
