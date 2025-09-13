-- vim: foldmethod=marker foldlevel=1

--[[ Neovim Options Configuration {{{1
This module configures Neovim's built-in options and settings.
Options are organized by category for easy maintenance and understanding.
}}}1 --]]

-- Global Configuration {{{1
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
-- }}}1

-- Performance Settings {{{1
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.lazyredraw = true
vim.opt.synmaxcol = 200
vim.opt.re = 0

-- Global performance thresholds (used by Treesitter and large-file guards)
vim.g.large_file_threshold_bytes = vim.g.large_file_threshold_bytes or 200 * 1024
vim.g.synmaxcol_limit = vim.g.synmaxcol_limit or 3000
-- }}}1

-- UI and Display {{{1
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.mouse = ''

-- Window behavior
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 8

-- Whitespace visualization
vim.opt.list = true
vim.opt.listchars = {
  tab = '» ',
  trail = '·',
  nbsp = '␣',
  extends = '❯',
  precedes = '❮',
}

-- Float defaults and visible borders
vim.api.nvim_set_hl(0, 'FloatBorder', vim.api.nvim_get_hl(0, { name = 'WinSeparator', link = false }))
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('UIFloatBorder', { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, 'FloatBorder', { link = 'WinSeparator' })
  end,
})
-- }}}1

-- Editor Behavior {{{1
-- Indentation
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = 'split'
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Text handling
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.wrap = false
vim.opt.textwidth = 80

-- Completion
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.pumheight = 10
-- }}}1

-- Folding Configuration {{{1
-- Defaults; auto-setup below will adjust per buffer
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldnestmax = 4
vim.opt.foldcolumn = '1'
vim.opt.foldenable = true
-- Set a safe default foldtext; per-buffer auto-setup may switch to TS foldtext
vim.opt.foldtext = 'v:lua.require("core.extras.folds").summary()'

-- Auto-select marker vs Treesitter vs indent per buffer
do
  local group = vim.api.nvim_create_augroup('FoldMethodAuto', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile', 'FileType' }, {
    group = group,
    callback = function(args)
      -- Defer to ensure modelines have been processed
      vim.schedule(function()
        local ok, folds = pcall(require, 'core.extras.folds')
        if ok and folds and type(folds.auto_setup) == 'function' then
          folds.auto_setup(args.buf)
        end
      end)
    end,
  })
end
-- }}}1

-- File and Buffer Management {{{1
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.confirm = true
vim.opt.autoread = true
vim.opt.hidden = true
vim.opt.fileencoding = 'utf-8'
vim.opt.fileformat = 'unix'
-- }}}1

-- Environment-Specific Settings {{{1
if vim.fn.has 'nvim-0.10' == 1 then
  vim.opt.smoothscroll = true
end

-- Clipboard configuration
if vim.fn.has 'wsl' == 1 then
  vim.g.clipboard = {
    name = 'WslClipboard',
    copy = { ['+'] = 'clip.exe', ['*'] = 'clip.exe' },
    paste = {
      ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
else
  vim.opt.clipboard = 'unnamedplus'
end
-- }}}1
