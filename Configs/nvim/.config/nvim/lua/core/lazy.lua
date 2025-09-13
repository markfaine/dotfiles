-- vim: foldmethod=marker foldlevel=1

--[[ Lazy.nvim Plugin Manager Configuration {{{1
This module installs and configures the Lazy.nvim plugin manager for
fast, lazy-loaded plugin management with performance optimizations.
}}}1 --]]

-- Bootstrap Installation {{{1
local function install_lazy()
  local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

  if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.notify('Installing lazy.nvim...', vim.log.levels.INFO)

    local out = vim.fn.system({
      'git', 'clone', '--filter=blob:none', '--branch=stable',
      'https://github.com/folke/lazy.nvim.git', lazypath,
    })

    if vim.v.shell_error ~= 0 then
      error('Failed to install lazy.nvim:\n' .. out)
    end
  end

  vim.opt.rtp:prepend(lazypath)
end

install_lazy()
-- }}}1

-- Configuration {{{1
local config = {
  defaults = { lazy = true },

  spec = {
    { import = 'plugins' },
  },

  install = {
    colorscheme = { 'tokyonight-night', 'habamax' },
    missing = true,
  },

  checker = {
    enabled = false,   -- disable background update checker
    notify = false,
    frequency = 3600,
  },

  change_detection = {
    enabled = false,   -- disable background change detection
    notify = false,
  },

  performance = {
    cache = { enabled = true },
    reset_packpath = true,
    rtp = {
      reset = true,
      disabled_plugins = {
        -- File management
        'netrw', 'netrwPlugin', 'netrwSettings', 'netrwFileHandlers',
        -- Archives
        'gzip', 'zip', 'zipPlugin', 'tar', 'tarPlugin', 'vimball', 'vimballPlugin',
        -- Web/HTML
        '2html_plugin', 'tohtml',
        -- Scripts
        'getscript', 'getscriptPlugin', 'logipat',
        -- Utilities
        'rrhelper', 'spellfile_plugin', 'tutor', 'rplugin',
        'compiler', 'bugreport', 'optwin', 'synmenu',
      },
    },
  },

  ui = {
    size = { width = 0.8, height = 0.8 },
    border = 'rounded',
    backdrop = 60,
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘', config = '🛠', event = '📅', ft = '📂', init = '⚙',
      keys = '🗝', plugin = '🔌', runtime = '💻', require = '🌙',
      source = '📄', start = '🚀', task = '📌', lazy = '💤 ',
    },
  },
}
-- }}}1

-- Setup {{{1
local ok, lazy = pcall(require, 'lazy')
if not ok then
  vim.notify('Failed to load lazy.nvim', vim.log.levels.ERROR)
  return
end

lazy.setup(config)
-- }}}1

