-- Key mapping - helps you remember your Neovim keymaps,
-- by showing available keybindings in a popup as you type.
-- See: https://github.com/folke/which-key.nvim
return {
  {
    "folke/which-key.nvim",
    dependencies = {
      {
        { "echasnovski/mini.nvim", version = false },
        "nvim-tree/nvim-web-devicons",
        opts = function()
          dofile(vim.g.base46_cache .. "devicons")
          --return { override = require "nvchad.icons.devicons" }
        end,
      },
    },
    lazy = false,
    keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g", "<A>", "<M>", "<T>", "<C>" },
    cmd = "WhichKey",
    opts = {
      spec = {
        { "<T-b>", group = "Buffers" },
        { "<leader>a", group = "Ansible", icon = "󱂚" },
        { "<leader>d", group = "Docstring", icon = "󰈙" },
        { "<leader>f", group = "Formatting" },
        { "<leader>g", group = "Git" },
        { "<leader>n", group = "Explorer" },
        { "<leader>p", group = "Picker" },
        { "<leader>t", group = "Toggles" },
        { "<leader>T", group = "Typewriter" },
        { "<leader>w", group = "Whichkey" },
      },
    },
    dofile(vim.g.base46_cache .. "whichkey"),
    event = "VeryLazy",
  },
}
