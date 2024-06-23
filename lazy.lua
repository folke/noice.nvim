return {
  -- nui.nvim can be lazy loaded
  { "MunifTanjim/nui.nvim", lazy = true },
  {
    "folke/noice.nvim",
    event = "VeryLazy", -- load noice on the VeryLazy event
    opts = {}, -- this will ensure noice is always setup
  },
}
