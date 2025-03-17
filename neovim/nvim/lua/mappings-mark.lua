require "nvchad.mappings"

local map = vim.keymap.set
local nomap = vim.keymap.del

-- -- General mappings
-- ; switch to command mode from normal mode
map("n", ";", ":", { desc = "CMD enter command mode" })

-- jk in insert mode is escape
map("i", "jk", "<ESC>")

-- search and replace word under cursor
map("n", "<leader>r", ":%s/\\<<C-r><C-w>\\>/", { desc = "Replace word under cursor" })

-- -- End General Mappings

-- -- Quick Actions (common operations)
-- , - for common operations
--  toggle comment
map("n", ",", "Quick actions")
map("n", ",/", "gcc", { desc = "toggle comment", remap = true })

-- toggle comment (visual mode)
map("v", ",/", "gc", { desc = "toggle comment", remap = true })

-- NvimTree toggle
map("n", ",n", "<cmd>NvimTreeToggle<CR>", { desc = "toggle tree window" })

-- Lsp hover
nomap("n", "<leader>K")
map("n", ",h", vim.lsp.buf.hover, { desc = "Hover" })
-- -- End Quick Actions

-- <leader>a
map("n", "<leader>a", "Unused")

-- <leader>b
map("n", "<leader>b", "Unused")

-- -- Comments
-- <leader>c Comments - key bindings for anything to do with comments
map("n", "<leader>c", "Comments")

-- toggle comment
-- These are also bound to , since it's used for common operations
-- disable stock bindings - comments
nomap("n", "<leader>/")
nomap("v", "<leader>/")
map("n", "<leader>c/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>c/", "gc", { desc = "toggle comment", remap = true })
-- -- End Comments

-- <leader>d
map("n", "<leader>d", "Unused")
-- <leader>e
map("n", "<leader>e", "Unused")
-- <leader>f
map("n", "<leader>f", "Unused")

-- -- Gitsigns
-- disable stock bindings - Gitsigns
nomap("n", "<leader>n")

-- <leader>g Gitsigns - mapping to toggle Gitsigns
map("n", "<leader>g", "Git")
map("n", "<leader>tg", "<cmd>Gitsigns toggle_signs<cr>", { desc = "Toggle Gitsigns" })
-- -- End Gitsigns

-- <leader>h
map("n", "<leader>h", "Unused")

-- <leader>i
map("n", "<leader>i", "Unused")

-- <leader>j
map("n", "<leader>j", "Unused")

-- <leader>k
map("n", "<leader>k", "Unused")

-- <leader>l
map("n", "<leader>l", "Unused")

-- <leader>m
map("n", "<leader>m", "Unused")

-- -- Nvimtree
-- disable stock bindings - Nvimtree
nomap("n", "<C-n>")
nomap("n", "<leader>e")

-- <leader>n -Nvimtree - all things nvimtree
map("n", "<leader>n", "NvimTree")
map("n", "<leader>nt", "<cmd>NvimTreeToggle<CR>", { desc = "toggle tree window" })
map("n", "<leader>nf", function()
  if vim.fn.bufname():match "NvimTree_" then
    vim.cmd.wincmd "p"
  else
    vim.cmd "NvimTreeFindFile"
  end
end, { desc = "Toggle tree focus" })
map("n", "<leader>np", "<cmd>lua require('nvim-tree.api').tree.toggle(false, true)<CR>", { desc = "Tree peek" })
-- -- End Nvimtree

-- -- Toggles
-- <leader>t -Toggle - Toggles
map("n", "<leader>t", "Toggle")

-- Mapping to toggle indentation lines
map("n", "<leader>ti", function()
  require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled })
end, { desc = "Toggle Indention Lines" })

-- Toggle line numbers
map("n", "<leader>tn", "<cmd>set nu!<CR>", { desc = "toggle line number" })

-- Toggle relative line numbers
map("n", "<leader>tr", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })

-- Toggle cheatcheat
map("n", "<leader>th", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })

-- Mapping to toggle all visible markings
map("n", "<leader>ta", function()
  require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled })
  vim.cmd(string.format("%s", "set nu!"))
  vim.cmd(string.format("%s", "Gitsigns toggle_signs"))
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle All Visible Markers" })

-- Toggle LSP
map("n", "<leader>tp", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle LSP" })
-- -- End Toggles

-- -- LSP
-- <leader>l -LSP - Toggles
map("n", "<leader>l", "LSP")
-- -- End LSP

-- -- Navigation
-- Move between open terminal fuffers
map("t", "<C-w>h", "<C-\\><C-n><C-w>h", { silent = true, desc = "Navigate Terminal Buffer" })
-- -- End Navigation
