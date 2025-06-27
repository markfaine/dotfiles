-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`
require 'snacks'
-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
--vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
--vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
--vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
--vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
--vim.keymap.set('n', '<C-S-h>', '<C-w>H', { desc = 'Move window to the left' })
--vim.keymap.set('n', '<C-S-l>', '<C-w>L', { desc = 'Move window to the right' })
--vim.keymap.set('n', '<C-S-j>', '<C-w>J', { desc = 'Move window to the lower' })
--vim.keymap.set('n', '<C-S-k>', '<C-w>K', { desc = 'Move window to the upper' })

-- Open scratch window
vim.keymap.set('n', '<leader>.', function()
  Snacks.scratch()
end, { desc = 'Toggle Scratch Buffer' })
-- Selectscratch window
vim.keymap.set('n', '<leader>S', function()
  Snacks.scratch().select()
end, { desc = 'Select Scratch Buffer' })
-- Close scratch window
vim.keymap.set('n', '<leader>X', 'C-Wo', { desc = 'Close Scratch Buffer' })

-- -- Toggles
vim.keymap.set('n', '<leader>nr', '<Cmd>set relativenumber!<CR>', { desc = 'toggle relative line number' })
vim.keymap.set('n', '<leader>tn', '<cmd>set nu!<CR>', { desc = 'toggle line number' })
vim.keymap.set('n', '<leader>trn', '<cmd>set rnu!<CR>', { desc = 'toggle relative number' })
-- -- Comments
vim.keymap.set('n', '<leader>/', 'gcc', { desc = 'toggle comment', remap = true })
vim.keymap.set('v', '<leader>/', 'gc', { desc = 'toggle comment', remap = true })
-- -- Buffers
vim.keymap.set('n', '<leader>b', '<cmd>enew<CR>', { desc = 'buffer new' })
vim.keymap.set('n', '<leader>bn', '<cmd>bn<CR>', { desc = 'buffer next' })
vim.keymap.set('n', '<leader>bp', '<cmd>bp<CR>', { desc = 'buffer previous' })
vim.keymap.set('n', '<leader>x', '<cmd>bd<CR>', { desc = 'close buffer' })
-- todo: think of a different keymap for this
-- vim.keymap.set('n', '<leader>X', '<cmd>bw<CR>', { desc = 'close buffer' })
vim.keymap.set('n', '<leader>Q', '<cmd>:w | %bd | e#<CR>', { desc = 'close all buffers' })
--
-- ---- Mapping to toggle all visible markings
vim.keymap.set('n', '<leader>ta', function()
  require('ibl').setup_buffer(0, { enabled = not require('ibl.config').get_config(0).enabled })
  vim.cmd 'set relativenumber!'
  vim.cmd 'set nu!'
  --vim.cmd 'Gitsigns toggle_signs'
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  Snacks.toggle.indent()
end, { desc = 'Toggle All Visible Markers' })
