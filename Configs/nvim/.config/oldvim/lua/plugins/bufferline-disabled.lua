vim.opt.termguicolors = true
local map = vim.keymap.set
return {
  {
    "akinsho/bufferline.nvim",
    lazy = false,
    enabled = false,
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
  },
}
