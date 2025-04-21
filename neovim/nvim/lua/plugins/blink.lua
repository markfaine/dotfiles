return {
  "saghen/blink.nvim",
  lazy = false,
  build = "cargo build --release", -- for delimiters
  keys = {
    -- chartoggle
    {
      "<C-;>",
      function()
        require("blink.chartoggle").toggle_char_eol ";"
      end,
      mode = { "n", "v" },
      desc = "Toggle ; at eol",
    },
    {
      ",",
      function()
        require("blink.chartoggle").toggle_char_eol ","
      end,
      mode = { "n", "v" },
      desc = "Toggle , at eol",
    },
  },
  -- all modules handle lazy loading internally
  opts = {
    chartoggle = { enabled = false },
    cmp = { enabled = false },
    indent = { enabled = false },
    tree = { enabled = false },
    pairs = { enabled = false },
    select = { enabled = false },
    delimiters = {
      enabled = true,
      priority = 200,
      ns = vim.api.nvim_create_namespace "blink.delimiters",
      debug = false,
      highlights = {
        "RainbowOrange",
        "RainbowPurple",
        "RainbowBlue",
      },
    },
  },
}
