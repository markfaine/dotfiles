-- Neovim Options

-- Set leader  {{{
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
-- End Set leader  }}}

-- Disable mouse support  {{{
vim.opt.mouse = ''
-- End Disable mouse support  }}}

-- Enable Folding  {{{
-- https://neovim.io/doc/user/fold.html
vim.opt.foldlevelstart = 1
vim.opt.foldlevel = 99
vim.opt.foldmethod = 'marker'
vim.opt.foldnestmax = 4
vim.opt.foldcolumn = '0'
-- vim.opt.foldtext = ''
-- End Enable Folding  }}}

-- Nerd Font Enabled  {{{
vim.g.have_nerd_font = true
-- End Nerd Font Enabled  }}}

-- Make line numbers on by default {{{
vim.opt.number = true
vim.opt.relativenumber = true
-- End Make line numbers on by default }}}

-- Don't show the mode, since it's already in the status line {{{
vim.opt.showmode = false
-- End Don't show the mode, since it's already in the status line }}}

-- Sync clipboard between OS and Neovim. {{{
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)
-- End Sync clipboard between OS and Neovim. }}}

-- Fix issue with tmux breaking vim theme colors {{{
vim.opt.termguicolors = true
-- End Fixes issue with tmux breaking vim theme colors }}}

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Banish all tabs to the pits of hell
vim.opt.expandtab = true -- expand tab input with spaces characters
vim.opt.smartindent = true -- syntax aware indentations for newline inserts
vim.opt.tabstop = 2 -- num of space characters per tab, this is default, also specified by file type
vim.opt.shiftwidth = 2 -- spaces per indentation level

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.opt.confirm = true
