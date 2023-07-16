local Markdown = require("noice.text.markdown")

local M = {}

local ns = vim.api.nvim_create_namespace("noice_test")

function M.test()
  describe("markdown", function()
    it("parse", function()
      for _, test in ipairs(M.tests) do
        assert.same(test.output, Markdown.parse(test.input))
      end
    end)

    it("conceal escape characters", function()
      local chars = "\\`*_{}[]()#+-.!"
      local buf = vim.api.nvim_create_buf(false, true)

      ---@type string[]
      local lines = {}
      for i = 1, #chars do
        local char = chars:sub(i, i)
        table.insert(lines, "\\" .. char)
      end
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

      Markdown.conceal_escape_characters(buf, ns, { 0, 0, #lines - 1, 1 })
      local extmarks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
      assert.equal(chars:len(), #extmarks)
    end)
  end)
end

M.tests = {
  {
    input = [[



    foo

    ]],
    output = {
      { line = "    foo" },
    },
  },
  {
    input = [[
    bar


    ---

    foo

    ]],
    output = {
      { line = "    bar" },
      { line = "---" },
      { line = "    foo" },
    },
  },
  {
    input = [[
```lua
local a
```

foo

```lua
local b
```
    ]],
    output = {
      { code = { "local a" }, lang = "lua" },
      { line = "" },
      { line = "foo" },
      { line = "" },
      { code = { "local b" }, lang = "lua" },
    },
  },
  {
    input = [[

```lua
local a
```
```lua
local b
```
    ]],
    output = {
      { code = { "local a" }, lang = "lua" },
      { line = "" },
      { code = { "local b" }, lang = "lua" },
    },
  },
  {
    input = [[

&lt;foo
    ]],
    output = {
      { line = "<foo" },
    },
  },
  {
    input = [[

    ```lua
local a
    ```

    ]],
    output = {
      { code = { "local a" }, lang = "lua" },
    },
  },
  {
    input = [[

    ```lua
local a
local b
]],
    output = {
      { code = { "local a", "local b", "" }, lang = "lua" },
    },
  },
  {
    input = [[

   ***

    ```lua
local a
    ```

    ---

    ]],
    output = {
      { line = "---" },
      { code = { "local a" }, lang = "lua" },
      { line = "---" },
    },
  },
  {
    input = [[

   ***

    ```   lua
local a
    ```

    ---

    ]],
    output = {
      { line = "---" },
      { code = { "local a" }, lang = "lua" },
      { line = "---" },
    },
  },
  {
    input = [[

```lua
local a
```

foo

bar

```
local b
```

    ]],
    output = {
      { code = { "local a" }, lang = "lua" },
      { line = "" },
      { line = "foo" },
      { line = "" },
      { line = "bar" },
      { line = "" },
      { code = { "local b" }, lang = "text" },
    },
  },
  {
    input = [[

1 &lt; 2
3 &gt; 2
&quot;quoted&quot;
&apos;apos&apos;
&ensp;&emsp;indented
&amp;
    ]],
    output = {
      { line = "1 < 2" },
      { line = "3 > 2" },
      { line = '"quoted"' },
      { line = "'apos'" },
      { line = "  indented" },
      { line = "&" },
    },
  },
}
M.test()
