require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
-- local wk = require("which-key")
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Mapping to toggle indentation lines
map("n", "<leader>ti", function() require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled, }) end, { desc = "Toggle Indention Lines"})

-- Mapping to toggle Gitsigns
map("n", "<leader>tg", "<cmd>Gitsigns toggle_signs<cr>" , { desc = "Toggle Indention Lines"})

-- Mapping to toggle all visible markings
map("n", "<leader>ta", function() 
  require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled, })
  vim.cmd(string.format("%s", "set nu!"))
  vim.cmd(string.format("%s", "Gitsigns toggle_signs"))
end, { desc = "Toggle All Visible Markers"})

require("ibl").setup_buffer(0, { enabled = true, })
