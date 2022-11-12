local Markdown = require("noice.text.markdown")

local M = {}

function M.test()
  describe("markdown", function()
    it("parse", function()
      for _, test in ipairs(M.tests) do
        assert.same(test.output, Markdown.parse(test.input))
      end
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
}
M.test()
