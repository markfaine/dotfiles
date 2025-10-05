-- vim: foldmethod=marker foldlevel=1

--[[ Autocommands Configuration {{{1
Automatic commands that enhance the Neovim experience.
Organized by category for easy maintenance.
}}}1 --]]

-- Autocommand Groups {{{1
local augroups = {
  general = vim.api.nvim_create_augroup('GeneralSettings', { clear = true }),
  formatting = vim.api.nvim_create_augroup('Formatting', { clear = true }),
  buffers = vim.api.nvim_create_augroup('BufferManagement', { clear = true }),
  filetypes = vim.api.nvim_create_augroup('FileTypeSettings', { clear = true }),
  performance = vim.api.nvim_create_augroup('Performance', { clear = true }),
}
-- }}}1

-- General Editor Behavior {{{1
-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked text',
  group = augroups.general,
  callback = function()
    vim.highlight.on_yank({ higroup = 'Visual', timeout = 200 })
  end,
})

-- Restore cursor position
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Restore cursor position',
  group = augroups.general,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto-reload files when changed externally
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  desc = 'Auto-reload file if changed externally',
  group = augroups.general,
  command = 'checktime',
})

-- Equalize splits on resize
vim.api.nvim_create_autocmd('VimResized', {
  desc = 'Equalize splits on resize',
  group = augroups.general,
  command = 'wincmd =',
})
-- }}}1

-- Formatting and Cleanup {{{1
-- Remove trailing whitespace on save
vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Remove trailing whitespace',
  group = augroups.formatting,
  callback = function()
    local save_cursor = vim.fn.getpos('.')
    pcall(function() vim.cmd([[%s/\s\+$//e]]) end)
    vim.fn.setpos('.', save_cursor)
  end,
})

-- Convert tabs to spaces for shell scripts
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Convert tabs to spaces in shell scripts',
  group = augroups.formatting,
  pattern = { '*.sh', '*.bash', '*.zsh' },
  callback = function()
    vim.cmd('silent! %retab')
  end,
})
-- }}}1

-- File Type Specific Settings {{{1
-- Disable auto-commenting
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Disable auto-commenting',
  group = augroups.filetypes,
  pattern = '*',
  callback = function()
    vim.opt_local.formatoptions:remove({ 'c', 'r', 'o' })
  end,
})

-- Enable spell check for text files
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable spell check for text files',
  group = augroups.filetypes,
  pattern = { 'markdown', 'text', 'gitcommit' },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 80
  end,
})

-- Close certain buffers with 'q'
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Close with q',
  group = augroups.buffers,
  pattern = { 'help', 'qf', 'lspinfo', 'man', 'notify' },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = event.buf, silent = true })
  end,
})
-- }}}1

-- Performance Optimizations {{{1
-- Disable features for large files
vim.api.nvim_create_autocmd('BufReadPre', {
  desc = 'Optimize for large files',
  group = augroups.performance,
  callback = function()
    local max_filesize = vim.g.large_file_threshold_bytes or (1000 * 1024)
    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(0))
    if ok and stats and stats.size > max_filesize then
      vim.cmd('syntax off')
      vim.opt_local.foldmethod = 'manual'
      vim.opt_local.undolevels = -1
      vim.opt_local.swapfile = false
    end
  end,
})

-- Limit syntax highlighting column
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Limit syntax highlighting for performance',
  group = augroups.performance,
  pattern = '*',
  callback = function()
    vim.opt_local.synmaxcol = vim.g.synmaxcol_limit or 200
  end,
})

-- Large-file guard: keep editing responsive on big files
vim.api.nvim_create_augroup('LargeFileGuard', { clear = true })
vim.api.nvim_create_autocmd('BufReadPre', {
  group = 'LargeFileGuard',
  callback = function(args)
    local limit = vim.g.large_file_threshold_bytes or 200 * 1024
    local fs = (vim.uv or vim.loop).fs_stat
    local ok, stat = pcall(fs, args.file)
    if ok and stat and stat.size > limit then
      vim.b.large_file = true
      vim.opt_local.swapfile = false
      vim.opt_local.undofile = false
      vim.opt_local.foldmethod = 'manual'
      vim.opt_local.synmaxcol = vim.g.synmaxcol_limit or 3000
    end
  end,
})
-- }}}1

-- UI availability helper
local M = {}
function M.is_ui() return not vim.g.started_by_firenvim and #vim.api.nvim_list_uis() > 0 end
return M
