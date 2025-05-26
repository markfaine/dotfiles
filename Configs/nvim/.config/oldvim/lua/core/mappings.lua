local map = vim.keymap.set

-- Enter cmd mode
map("n", ";", ":", { desc = "CMD enter command mode" })
--
-- jk in insert mode is escape
map("i", "jk", "<ESC>")

-- line motion vs visual line navigation
-- Map j/k to m'<num>j/k if num, else gj/gk
map("n", "j", function()
  return vim.v.count > 0 and "m'" .. vim.v.count .. "j" or "gj"
end, { expr = true })

-- search and replace word under cursor
map("n", "<leader>r", ":%s/\\<<C-r><C-w>\\>/", { desc = "Replace word under cursor" })

-- window navigation
map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })

-- highlights
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

-- Save/Copy
map("n", "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

-- Toggles
map("n", "<leader>nr", "<Cmd>set relativenumber!<CR>", { desc = "toggle relative line number" })
map("n", "<leader>tn", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>trn", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })

---- Mapping to toggle all visible markings
map("n", "<leader>ta", function()
  require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled })
  vim.cmd "set relativenumber!"
  vim.cmd "set nu!"
  vim.cmd "Gitsigns toggle_signs"
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  --Snacks.toggle.indent()
end, { desc = "Toggle All Visible Markers" })

-- Formatting
map("n", "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "general format file" })

-- buffers
map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })
map("n", "<leader>x", "<cmd>bd<CR>", { desc = "close buffer" })
map("n", "<leader>X", "<cmd>bw<CR>", { desc = "close buffer" })
map("n", "<leader>Q", "<cmd>:w | %bd | e#<CR>", { desc = "close all buffers" })

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- nvimtree/file explorer
map("n", "<leader>nn", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>nf", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- term
map({ "n", "t" }, "<A-v>", function()
  require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }
end, { desc = "terminal toggleable vertical term" })

map({ "n", "t" }, "<A-h>", function()
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "terminal toggleable horizontal term" })

map({ "n", "t" }, "<A-i>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })

-- whichkey
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })
map("n", "<C-A-S-Q> callback = function()", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })

map("n", "<leader>wk", function()
  vim.cmd("WhichKey " .. vim.fn.input "WhichKey: ")
end, { desc = "whichkey query lookup" })
