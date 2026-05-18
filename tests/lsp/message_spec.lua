local Message = require("noice.lsp.message")

describe("lsp messages", function()
  it("installs the window/showMessage handler", function()
    local original = vim.lsp.handlers["window/showMessage"]

    Message.setup()

    assert.equal(Message.on_message, vim.lsp.handlers["window/showMessage"])

    vim.lsp.handlers["window/showMessage"] = original
  end)
end)
