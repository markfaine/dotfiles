-- [[ Basic Autocommands ]]

-- Highlight when yanking (copying) text {{{
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
-- End Highlight when yanking (copying) text }}}

-- Banish tab characters to the pits of hell! {{{
vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
  pattern = '*.sh',
  callback = function()
    vim.cmd.normal ':retab'
  end,
})
-- End Banish tab characters to the pits of hell! }}}

-- Works in progress {{{
--
-- vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
--   pattern = '*.sh',
--   callback = function()
--     vim.cmd.normal ':%s/\\r//g'
--   end,
-- })
--

-- Format on open {{{
-- vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
--   pattern = '*',
--   callback = function()
--     require('conform').format { async = true, lsp_format = 'fallback' }
--   end,
-- })
-- End Format on open }}}

-- Create an autocommand to add folding to every file
-- vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
--   pattern = '*',
--   callback = function()
--     vim.opt.foldlevel = 0
--     vim.opt.foldnestmax = 2
--     vim.opt.foldmethod = 'marker'
--   end,
-- })
-- }}}

-- Works in progress }}}
-- End [[ Basic Autocommands ]]
