local M = {}

--TODO: make configurable
---@type table<string, NoiceFormat>
M.formats = {
  default = { "{level} ", "{title} ", "{message}" },
  notify = { "{message}" },
  details = {
    "{level} ",
    "{date} ",
    "{event}",
    { "{kind}", before = { ".", hl_group = "Comment" } },
    " ",
    "{title} ",
    "{message}",
  },
  telescope = {
    "{level} ",
    "{date} ",
    "{title} ",
    "{message}",
  },
  telescope_preview = {
    "{level} ",
    "{date} ",
    "{event}",
    { "{kind}", before = { ".", hl_group = "Comment" } },
    "\n",
    "{title}\n",
    "\n",
    "{message}",
  },
  lsp_progress = {
    {
      "{progress} ",
      key = "progress.percentage",
      contents = {
        { "{data.progress.message} ", hl_group = nil },
      },
    },
    "({data.progress.percentage}%) ",
    { "{spinner} ", hl_group = "Constant" },
    { "{data.progress.title} ", hl_group = "NonText" },
    { "{data.progress.client_name} ", hl_group = "Title" },
  },
  lsp_progress_done = {
    { "✔ ", hl_group = "Constant" },
    { "{data.progress.title} ", hl_group = "NonText" },
    { "{data.progress.client_name} ", hl_group = "Title" },
  },
}

-- TODO: move hl groups to config.highlights
---@class NoiceFormatOptions
M.defaults = {
  ---@class NoiceFormatOptions.debug
  debug = {},
  ---@class NoiceFormatOptions.level
  level = {
    hl_group = {
      debug = "Comment",
      trace = "Comment",
      off = "Comment",
      error = "DiagnosticVirtualTextError",
      warn = "DiagnosticVirtualTextWarn",
      info = "DiagnosticVirtualTextInfo",
    },
    icons = { error = " ", warn = " ", info = " " },
  },
  ---@class NoiceFormatOptions.progress
  progress = {
    ---@type NoiceFormat
    contents = {},
    width = 20,
    align = "right",
    key = "progress", -- key in message.opts For example: "progress.percentage"
    hl_group = "NoiceProgressTodo",
    hl_group_done = "NoiceProgressDone",
  },
  ---@class NoiceFormatOptions.text
  text = {
    text = nil,
    hl_group = nil,
  },
  ---@class NoiceFormatOptions.spinner
  spinner = {
    ---@type Spinner
    name = "dots",
    hl_group = nil,
  },
  ---@class NoiceFormatOptions.data
  data = {
    key = nil,
    hl_group = nil,
  },
  ---@class NoiceFormatOptions.title
  title = {
    hl_group = "Identifier",
  },
  ---@class NoiceFormatOptions.event
  event = {
    hl_group = "Comment",
  },
  ---@class NoiceFormatOptions.kind
  kind = {
    hl_group = "Comment",
  },
  ---@class NoiceFormatOptions.date
  date = {
    format = "%X", --- @see https://www.lua.org/pil/22.1.html
    hl_group = "Special",
  },
  ---@class NoiceFormatOptions.message
  message = {
    hl_group = nil, -- if set, then the hl_group will be used instead of the message highlights
  },
  ---@class NoiceFormatOptions.confirm
  confirm = {
    hl_group = {
      choice = "CursorLine",
      default_choice = "Visual",
    },
  },
}

return M
