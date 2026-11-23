local Config = require("noice.config")
local UI = require("noice.ui")

describe("UI event routing", function()
  before_each(function()
    Config.setup()
    UI.setup()
  end)

  it("ignores the restart event", function()
    assert.is_nil(UI.get_handler("restart", "/tmp/nvim-restarted"))
  end)

  it("still routes supported message events", function()
    assert.equal(require("noice.ui.msg").on_show, UI.get_handler("msg_show", ""))
  end)
end)
