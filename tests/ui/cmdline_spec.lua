local Cmdline = require("noice.ui.cmdline")
local Manager = require("noice.message.manager")
local Message = require("noice.message")

describe("cmdline confirm", function()
  local handle_confirm

  before_each(function()
    handle_confirm = Cmdline.handle_confirm
    Cmdline.handle_confirm = true
    Cmdline.confirm_message = nil
    Cmdline._on_hide = nil
  end)

  after_each(function()
    Cmdline.handle_confirm = handle_confirm
    Cmdline.confirm_message = nil
    Cmdline._on_hide = nil
  end)

  it("separates the confirm message from the cmdline prompt", function()
    local message = Message("msg_show", "confirm", "Save changes? ")

    assert.is_true(Cmdline.on_confirm(message))
    Cmdline.on_show("cmdline_show", {}, 0, "", " &Yes\n&No", 0, 1)

    assert.equal("Save changes? \n &Yes\n&No", message:content())
    assert.is_true(Manager.has(message, { history = true }))
  end)

  it("does not add an extra separator when the confirm message already ends with an empty line", function()
    local message = Message("msg_show", "confirm", "Save changes? \n")

    assert.is_true(Cmdline.on_confirm(message))
    Cmdline.on_show("cmdline_show", {}, 0, "", " &Yes\n&No", 0, 1)

    assert.equal("Save changes? \n &Yes\n&No", message:content())
  end)

  it("does not handle confirm messages on Neovim versions without cmdline confirm prompts", function()
    Cmdline.handle_confirm = false

    local message = Message("msg_show", "confirm", "Save changes? ")

    assert.is_false(Cmdline.on_confirm(message))
    assert.equal("Save changes? ", message:content())
    assert.is_nil(Cmdline.confirm_message)
  end)
end)
