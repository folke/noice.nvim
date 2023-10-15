local lazy = require("noice.util.lazy")

describe("ffi", function()
  it("cmdpreview is false", function()
    assert(lazy("noice.util.ffi").cmdpreview == false)
  end)
end)
