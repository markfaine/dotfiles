require "nvchad.mappings"

local map = vim.keymap.set
local nomap = vim.keymap.del

----------------------- Disable nvchad stock keymappings if enabled -------------------
-- disable stock comment toggle keymap
nomap("n", "<leader>/")
nomap("v", "<leader>/")
-- disable stock bindings - Gitsigns
nomap("n", "<leader>n")
-- disable stock bindings - Nvimtree
nomap("n", "<C-n>")
nomap("n", "<leader>e")
----------------------   End --------------------------------------------------

----------------------- General mappings ---------------------------------------
-- ; switch to command mode from normal mode
map("n", ";", ":", { desc = "CMD enter command mode" })

-- jk in insert mode is escape
map("i", "jk", "<ESC>")

-- search and replace word under cursor
map("n", "<leader>r", ":%s/\\<<C-r><C-w>\\>/", { desc = "Replace word under cursor" })

-- lsp hover
map("n", ",K", vim.lsp.buf.hover, { desc = "Hover" })
-- -- End General Mappings

-----------------------End General mappings-------------------------------------

----------------------- Quick Actions (common operations) ----------------------
-- , - for common operations
--  toggle comment
map("n", ",", "Quick actions")
map("n", ",/", "gcc", { desc = "toggle comment", remap = true })

-- toggle comment (visual mode)
map("v", ",/", "gc", { desc = "toggle comment", remap = true })

-- NvimTree toggle
map("n", ",n", "<cmd>NvimTreeToggle<CR>", { desc = "toggle tree window" })

map("n", ",h", vim.lsp.buf.hover, { desc = "Hover" })
----------------------- End Quick Actions (common operations) ------------------

------------------------Leader a - Unsued -------------------------------------
-- <leader>a
map("n", "<leader>a", "<Nop>", { desc = "Unused" })

------------------------Leader b - Unsued -------------------------------------
-- <leader>b
map("n", "<leader>b", "<Nop>", { desc = "Unused" })

------------------------Leader c - Comments ------------------------------------
map("n", "<leader>c", "Comments")

-- toggle comment
-- These are also bound to , since it's used for common operations
map("n", "<leader>c/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>c/", "gc", { desc = "toggle comment", remap = true })
------------------------End Comments -------------------------------------------

------------------------Leader d - Unused --------------------------------------
map("n", "<leader>d", "<Nop>", { desc = "Unused" })
------------------------Leader e - Unused --------------------------------------
map("n", "<leader>e", "<Nop>", { desc = "Unused" })
------------------------Leader f - Unused --------------------------------------
map("n", "<leader>f", "<Nop>", { desc = "Unused" })

------------------------Leader g - Gitsigns ------------------------------------
-- <leader>g Gitsigns - mapping to toggle Gitsigns
map("n", "<leader>g", "Git")
map("n", "<leader>gt", "<cmd>Gitsigns toggle_signs<cr>", { desc = "Toggle Gitsigns" })
------------------------End Gitsigns ------------------------------------

------------------------Leader i - Unused --------------------------------------
map("n", "<leader>i", "<Nop>", { desc = "Unused" })

------------------------Leader j - Unused --------------------------------------
map("n", "<leader>j", "<Nop>", { desc = "Unused" })

------------------------Leader k - Unused --------------------------------------
map("n", "<leader>k", "<Nop>", { desc = "Unused" })

------------------------Leader l - Unused --------------------------------------
map("n", "<leader>l", "<Nop>", { desc = "Unused" })

------------------------Leader m - Unused --------------------------------------
map("n", "<leader>m", "<Nop>", { desc = "Unused" })

------------------------Leader n - Nvimtree ------------------------------------
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
------------------------End Nvimtree ------------------------------------

------------------------Leader o - Unused --------------------------------------
map("n", "<leader>o", "<Nop>", { desc = "Unused" })
------------------------Leader p - Unused --------------------------------------
map("n", "<leader>p", "<Nop>", { desc = "Unused" })
------------------------Leader q - Unused --------------------------------------
map("n", "<leader>q", "<Nop>", { desc = "Unused" })
------------------------Leader r - Unused --------------------------------------
map("n", "<leader>r", "<Nop>", { desc = "Unused" })
------------------------Leader s - Unused --------------------------------------
map("n", "<leader>s", "<Nop>", { desc = "Unused" })

------------------------Leader t - Toggles  ------------------------------------

map("n", "<leader>t", "Toggle")
map("n", "<leader>tg", "<cmd>Gitsigns toggle_signs<cr>", { desc = "Toggle Gitsigns" })
map("n", "<leader>ti", function()
  require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled })
end, { desc = "Toggle Indention Lines" })
map("n", "<leader>tn", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>tr", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
map("n", "<leader>th", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })
-- Mapping to toggle all visible markings
map("n", "<leader>ta", function()
  require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled })
  vim.cmd(string.format("%s", "set nu!"))
  vim.cmd(string.format("%s", "Gitsigns toggle_signs"))
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle All Visible Markers" })

------------------------Leader w - Whichkey --------------------------------------
map("n", "<leader>w", "Whichkey")
