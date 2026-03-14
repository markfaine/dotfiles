-- vim: foldmethod=marker foldlevel=1

--[[ Shell Script Configuration {{{1
Enhanced editing experience for shell scripts (bash, zsh, sh) with
validation, formatting, debugging tools, and smart mappings.
}}}1 --]]

-- Shell Settings {{{1
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.tabstop = 4
vim.opt_local.expandtab = true
vim.opt_local.smartindent = true

-- Shell-specific options
vim.opt_local.textwidth = 80
vim.opt_local.colorcolumn = '81'
vim.opt_local.wrap = false
vim.opt_local.foldmethod = 'marker'
vim.opt_local.foldlevel = 1

-- Show whitespace for shell scripts
vim.opt_local.list = true
vim.opt_local.listchars = {
  tab = '»·',
  trail = '·',
  extends = '❯',
  precedes = '❮',
  nbsp = '⦸',
}

-- Enable spell checking for comments
vim.opt_local.spell = true
vim.opt_local.spelllang = 'en_us'
-- }}}1

-- Shell Detection and Context {{{1
local function detect_shell_type()
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''
  local shell_type = 'sh' -- default

  if first_line:match('^#!/bin/bash') or first_line:match('^#!/usr/bin/bash') then
    shell_type = 'bash'
  elseif first_line:match('^#!/bin/zsh') or first_line:match('^#!/usr/bin/zsh') then
    shell_type = 'zsh'
  elseif first_line:match('^#!/bin/sh') then
    shell_type = 'sh'
  elseif first_line:match('^#!/usr/bin/env bash') then
    shell_type = 'bash'
  elseif first_line:match('^#!/usr/bin/env zsh') then
    shell_type = 'zsh'
  end

  vim.b.shell_type = shell_type
  return shell_type
end

-- Set shell type on buffer enter
vim.api.nvim_create_autocmd('BufEnter', {
  buffer = 0,
  callback = detect_shell_type,
  desc = 'Detect shell type from shebang'
})

-- Initialize shell type
detect_shell_type()
-- }}}1

-- Smart Shell Mappings {{{1
-- Quick shebang insertion
vim.keymap.set('i', '<C-s>', function()
  local shebangs = {
    '#!/bin/bash',
    '#!/bin/zsh',
    '#!/bin/sh',
    '#!/usr/bin/env bash',
    '#!/usr/bin/env zsh'
  }

  vim.ui.select(shebangs, {
    prompt = 'Select shebang:',
  }, function(choice)
    if choice then
      vim.api.nvim_buf_set_lines(0, 0, 0, false, { choice, '' })
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert shebang' })

-- Function creation
vim.keymap.set('i', '<C-f>', function()
  local indent = string.rep(' ', vim.fn.indent('.'))
  return 'function () {\n' .. indent .. '    \n' .. indent .. '}'
end, { buffer = true, expr = true, desc = 'Create shell function' })

-- Variable assignment
vim.keymap.set('i', '<C-v>', function()
  return '="${}"'
end, { buffer = true, expr = true, desc = 'Variable assignment with quotes' })

-- Conditional blocks
vim.keymap.set('i', '<C-i>', function()
  local conditions = { 'if', 'elif', 'case', 'while', 'for' }

  vim.ui.select(conditions, {
    prompt = 'Select condition type:',
  }, function(choice)
    if choice then
      local indent = string.rep(' ', vim.fn.indent('.'))
      local templates = {
        ['if'] = choice .. ' [[ ]]; then\n' .. indent .. '    \n' .. indent .. 'fi',
        ['elif'] = choice .. ' [[ ]]; then\n' .. indent .. '    ',
        ['case'] = choice .. ' "$" in\n' .. indent .. '    )\n' .. indent .. '        ;;\n' .. indent .. 'esac',
        ['while'] = choice .. ' [[ ]]; do\n' .. indent .. '    \n' .. indent .. 'done',
        ['for'] = choice .. ' var in ; do\n' .. indent .. '    \n' .. indent .. 'done'
      }
      vim.api.nvim_put(vim.split(templates[choice], '\n'), 'l', true, true)
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert conditional block' })

-- Navigation mappings
vim.keymap.set('n', ']]', '/^\\s*function\\|^[a-zA-Z_][a-zA-Z0-9_]*\\s*()<CR>',
  { buffer = true, desc = 'Next function' })
vim.keymap.set('n', '[[', '?^\\s*function\\|^[a-zA-Z_][a-zA-Z0-9_]*\\s*()<CR>',
  { buffer = true, desc = 'Previous function' })
vim.keymap.set('n', '}', '/^\\s*}\\s*$<CR>',
  { buffer = true, desc = 'Next closing brace' })
vim.keymap.set('n', '{', '?^\\s*{\\s*$<CR>',
  { buffer = true, desc = 'Previous opening brace' })
-- }}}1

-- Shell Validation and Tools {{{1
local function syntax_check()
  local run = require('core.extras.utility').run
  local current_file = vim.fn.expand('%:p')
  local shell_type = vim.b.shell_type or 'bash'

  run({ shell_type, '-n', current_file },
    function() vim.notify('✓ Shell syntax is valid', vim.log.levels.INFO) end,
    function(err) vim.notify('✗ Shell syntax errors:\n' .. err, vim.log.levels.ERROR) end)
end

local function shellcheck_lint()
  local run = require('core.extras.utility').run
  if vim.fn.executable('shellcheck') == 0 then
    vim.notify('shellcheck not available', vim.log.levels.ERROR)
    return
  end
  local current_file = vim.fn.expand('%:p')
  run({ 'shellcheck', '-f', 'gcc', current_file },
    function() vim.notify('✓ No shellcheck issues found', vim.log.levels.INFO) end,
    function(err) vim.notify('Shellcheck issues:\n' .. err, vim.log.levels.WARN) end)
end

local function format_shell()
  local run = require('core.extras.utility').run
  if vim.fn.executable('shfmt') == 0 then
    vim.notify('shfmt not available', vim.log.levels.ERROR)
    return
  end
  local current_file = vim.fn.expand('%:p')
  -- format file in place then reload buffer
  run({ 'shfmt', '-i', '4', '-ci', '-w', current_file },
    function()
      vim.cmd('edit!')
      vim.notify('Formatted with shfmt', vim.log.levels.INFO)
    end,
    function(err) vim.notify('Failed to format with shfmt:\n' .. err, vim.log.levels.ERROR) end)
end

local function make_executable()
  local run = require('core.extras.utility').run
  local current_file = vim.fn.expand('%:p')
  if current_file ~= '' then
    run({ 'chmod', '+x', current_file },
      function() vim.notify('Made file executable', vim.log.levels.INFO) end,
      function(err) vim.notify('Failed to make executable:\n' .. err, vim.log.levels.ERROR) end)
  end
end

local function debug_script()
  local current_file = vim.fn.expand('%:p')
  local shell_type = vim.b.shell_type or 'bash'

  vim.cmd('split')
  vim.cmd('terminal ' .. shell_type .. ' -x ' .. current_file)
end

local function check_best_practices()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local issues = {}

  for i, line in ipairs(lines) do
    -- Check for unquoted variables
    if line:match('%$[a-zA-Z_][a-zA-Z0-9_]*[^}]') and not line:match('".*%$.*"') then
      table.insert(issues, string.format('Line %d: Consider quoting variable', i))
    end

    -- Check for missing error handling
    if line:match('^%s*[a-zA-Z]') and not line:match('||') and not line:match('&&') then
      local prev_line = lines[i-1] or ''
      if not prev_line:match('set -e') and not line:match('if') then
        -- This is a basic check - could be expanded
      end
    end

    -- Check for hardcoded paths
    if line:match('/usr/local/') or line:match('/opt/') then
      table.insert(issues, string.format('Line %d: Consider using variables for paths', i))
    end
  end

  if #issues == 0 then
    vim.notify('✓ No obvious best practice issues found', vim.log.levels.INFO)
  else
    vim.notify('Best practice suggestions:\n' .. table.concat(issues, '\n'), vim.log.levels.WARN)
  end
end

-- Tool mappings
vim.keymap.set('n', '<leader>ss', syntax_check, { buffer = true, desc = 'Check shell syntax' })
vim.keymap.set('n', '<leader>sl', shellcheck_lint, { buffer = true, desc = 'Run shellcheck' })
vim.keymap.set('n', '<leader>sf', format_shell, { buffer = true, desc = 'Format with shfmt' })
vim.keymap.set('n', '<leader>sx', make_executable, { buffer = true, desc = 'Make executable' })
vim.keymap.set('n', '<leader>sd', debug_script, { buffer = true, desc = 'Debug script' })
vim.keymap.set('n', '<leader>sc', check_best_practices, { buffer = true, desc = 'Check best practices' })
-- }}}1

-- Shell Snippets {{{1
-- Set up snippet integration if LuaSnip is available
local ok, luasnip = pcall(require, 'luasnip')
if ok then
  luasnip.add_snippets('sh', {
    luasnip.snippet('strict', {
      luasnip.text_node({'#!/bin/bash', 'set -euo pipefail', ''}),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('func', {
      luasnip.text_node('function '),
      luasnip.insert_node(1, 'name'),
      luasnip.text_node({'() {', '    '}),
      luasnip.insert_node(0),
      luasnip.text_node({'', '}'}),
    }),

    luasnip.snippet('ifexists', {
      luasnip.text_node('if [[ -'),
      luasnip.choice_node(1, {
        luasnip.text_node('f'),
        luasnip.text_node('d'),
        luasnip.text_node('e'),
      }),
      luasnip.text_node(' "'),
      luasnip.insert_node(2, 'path'),
      luasnip.text_node({'" ]]; then', '    '}),
      luasnip.insert_node(0),
      luasnip.text_node({'', 'fi'}),
    }),

    luasnip.snippet('getopts', {
      luasnip.text_node({'while getopts "'}),
      luasnip.insert_node(1, 'abc:'),
      luasnip.text_node({'" opt; do', '    case $opt in'}),
      luasnip.text_node({'', '        '}),
      luasnip.insert_node(0),
      luasnip.text_node({'', '        \\?)', '            echo "Invalid option: -$OPTARG" >&2', '            exit 1', '            ;;', '    esac', 'done'}),
    }),
  })
end
-- }}}1

-- Shell Auto Commands {{{1
-- Auto-insert shebang for new files
vim.api.nvim_create_autocmd('BufNewFile', {
  buffer = 0,
  callback = function()
    if vim.fn.line('$') == 1 and vim.fn.getline(1) == '' then
      vim.api.nvim_buf_set_lines(0, 0, 0, false, { '#!/bin/bash', '', '' })
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
    end
  end,
  desc = 'Auto-insert shebang for new shell files'
})

-- Auto-format on save if shfmt is available
vim.api.nvim_create_autocmd('BufWritePre', {
  buffer = 0,
  callback = function()
    if vim.g.shell_auto_format and vim.fn.executable('shfmt') == 1 then
      format_shell()
    end
  end,
  desc = 'Auto-format shell scripts on save'
})

-- Highlight shell variables
vim.api.nvim_create_autocmd('BufEnter', {
  buffer = 0,
  callback = function()
    -- Add custom highlights for shell variables if desired
    -- This could be expanded with more sophisticated highlighting
  end,
  desc = 'Set up shell-specific highlighting'
})
-- }}}1

-- Shell Commands {{{1
-- Create useful commands for shell development
vim.api.nvim_create_user_command('ShellRun', function()
  local current_file = vim.fn.expand('%:p')
  if current_file ~= '' then
    vim.cmd('split')
    vim.cmd('terminal bash ' .. current_file)
  end
end, { desc = 'Run current shell script in terminal' })

vim.api.nvim_create_user_command('ShellLint', function()
  shellcheck_lint()
end, { desc = 'Run shellcheck on current file' })

vim.api.nvim_create_user_command('ShellFormat', function()
  format_shell()
end, { desc = 'Format current shell script with shfmt' })

vim.api.nvim_create_user_command('ShellExecutable', function()
  make_executable()
end, { desc = 'Make current shell script executable' })
-- }}}1
