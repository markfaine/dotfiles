-- TOML: lightweight, fast buffer-local setup

-- Indentation
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.smartindent = false

-- Editing/formatting behavior
vim.bo.commentstring = '# %s'
vim.opt_local.formatoptions = vim.opt_local.formatoptions
  - 't'  -- don’t auto-wrap text (keeps typing fast)
  + 'c'  -- auto-wrap comments using textwidth
  + 'q'  -- allow formatting of comments with gq
  - 'o'  -- don’t continue comments on new line via 'o'/'O'
  - 'r'  -- don’t auto-insert comment leader on <CR>
vim.opt_local.textwidth = 0       -- no hard wrap by default
vim.opt_local.synmaxcol = 200     -- cap regex highlight width for perf on long lines

-- Navigation quality-of-life
vim.opt_local.suffixesadd:append('.toml')

-- Async tools: prefer Conform; fallback to taplo if available
local function format_toml()
  -- Try Conform (non-blocking) if installed
  local ok, conform = pcall(require, 'conform')
  if ok then
    conform.format({ async = true, lsp_format = 'prefer' })
    return
  end

  -- Fallback to taplo CLI (async)
  if vim.fn.executable('taplo') == 1 then
    local run = require('core.extras.utility').run
    local file = vim.fn.expand('%:p')
    run({ 'taplo', 'fmt', '--write', file },
      function()
        vim.cmd('edit!') -- reload after in-place write
        vim.notify('Formatted with taplo', vim.log.levels.INFO)
      end,
      function(err)
        vim.notify('taplo format failed:\n' .. err, vim.log.levels.ERROR)
      end)
  else
    vim.notify('No formatter: install taplo or enable Conform formatter for toml', vim.log.levels.WARN)
  end
end

local function validate_toml()
  if vim.fn.executable('taplo') ~= 1 then
    vim.notify('taplo not available for validation', vim.log.levels.WARN)
    return
  end
  local run = require('core.extras.utility').run
  local file = vim.fn.expand('%:p')
  run({ 'taplo', 'check', file },
    function() vim.notify('✓ TOML is valid', vim.log.levels.INFO) end,
    function(err) vim.notify('✗ TOML validation failed:\n' .. err, vim.log.levels.ERROR) end)
end

-- Buffer-local keymaps
vim.keymap.set('n', '<leader>tf', format_toml, { buffer = true, desc = 'Format TOML' })
vim.keymap.set('n', '<leader>tv', validate_toml, { buffer = true, desc = 'Validate TOML' })