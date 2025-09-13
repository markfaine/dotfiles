-- vim: foldmethod=marker foldlevel=1

--[[ YAML Filetype Configuration {{{1
Enhanced editing experience for YAML files with validation,
smart mappings, and document type detection.
}}}1 --]]

-- YAML Settings {{{1
-- Standard YAML indentation (2 spaces, no tabs)
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true
vim.opt_local.smartindent = false
vim.opt_local.autoindent = true

-- YAML-specific options
vim.opt_local.textwidth = 80
vim.opt_local.colorcolumn = '81'
vim.opt_local.wrap = false
vim.opt_local.foldmethod = 'indent'
vim.opt_local.foldlevel = 1

-- Show whitespace (critical for YAML)
vim.opt_local.list = true
vim.opt_local.listchars = {
  tab = '»·',      -- Make tabs very visible
  trail = '·',
  extends = '❯',
  precedes = '❮',
  nbsp = '⦸',
}
-- }}}1

-- Smart YAML Mappings {{{1
-- Smart list item creation
vim.keymap.set('i', '<C-l>', function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, col)
  local indent = before_cursor:match('^%s*')

  if vim.trim(before_cursor) == '' then
    return '- '
  elseif before_cursor:match('%s*-%s*$') then
    return '\n' .. indent .. '  - '
  else
    return '\n' .. indent .. '- '
  end
end, { buffer = true, expr = true, desc = 'Smart YAML list item' })

-- Smart key-value pairs
vim.keymap.set('i', '<C-k>', ': ', { buffer = true, desc = 'YAML key-value separator' })

-- Block scalars
vim.keymap.set('i', '<C-b>', function()
  local indent = string.rep(' ', vim.fn.indent('.'))
  return '|\n' .. indent .. '  '
end, { buffer = true, expr = true, desc = 'YAML block scalar' })

-- Navigation
vim.keymap.set('n', ']]', '/^[a-zA-Z]<CR>', { buffer = true, desc = 'Next YAML section' })
vim.keymap.set('n', '[[', '?^[a-zA-Z]<CR>', { buffer = true, desc = 'Previous YAML section' })
vim.keymap.set('n', '}', '/^---\\s*$<CR>', { buffer = true, desc = 'Next YAML document' })
vim.keymap.set('n', '{', '?^---\\s*$<CR>', { buffer = true, desc = 'Previous YAML document' })
-- }}}1

-- YAML Tools {{{1
local function validate_yaml()
  local run = require('core.extras.utility').run
  local temp_file = vim.fn.tempname() .. '.yml'
  vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), temp_file)

  if vim.fn.executable('yamllint') == 1 then
    run({ 'yamllint', temp_file },
      function()
        vim.notify('✓ Valid YAML', vim.log.levels.INFO)
        vim.fn.delete(temp_file)
      end,
      function(err)
        vim.notify('✗ YAML validation failed:\n' .. err, vim.log.levels.ERROR)
        vim.fn.delete(temp_file)
      end)
  else
    vim.notify('yamllint not available', vim.log.levels.WARN)
    vim.fn.delete(temp_file)
  end
end

local function format_yaml()
  if vim.fn.executable('yq') == 1 then
    vim.cmd(':%!yq eval "." -')
    vim.notify('Formatted with yq', vim.log.levels.INFO)
  else
    vim.notify('yq not available', vim.log.levels.WARN)
  end
end

local function check_yaml_issues()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local issues = {}

  for i, line in ipairs(lines) do
    if line:match('\t') then
      table.insert(issues, string.format('Line %d: Contains tab character', i))
    end
    if line:match('%s+$') then
      table.insert(issues, string.format('Line %d: Trailing whitespace', i))
    end
    if line:match(':[^%s]') and not line:match('://') then
      table.insert(issues, string.format('Line %d: Missing space after colon', i))
    end
  end

  if #issues == 0 then
    vim.notify('✓ No YAML style issues found', vim.log.levels.INFO)
  else
    vim.notify('Found issues:\n' .. table.concat(issues, '\n'), vim.log.levels.WARN)
  end
end

-- Tool mappings
vim.keymap.set('n', '<leader>yv', validate_yaml, { buffer = true, desc = 'Validate YAML' })
vim.keymap.set('n', '<leader>yf', format_yaml, { buffer = true, desc = 'Format YAML' })
vim.keymap.set('n', '<leader>yc', check_yaml_issues, { buffer = true, desc = 'Check YAML issues' })
-- }}}1

-- Document Type Detection {{{1
local function detect_yaml_type()
  local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
  local content = table.concat(lines, '\n'):lower()

  if content:match('hosts:') or content:match('tasks:') then
    vim.b.yaml_type = 'ansible'
    -- Ansible task template
    vim.keymap.set('i', '<C-t>', '- name: \n  ', { buffer = true, desc = 'Ansible task' })
  elseif content:match('apiversion:') or content:match('kind:') then
    vim.b.yaml_type = 'kubernetes'
  elseif content:match('version:') and content:match('services:') then
    vim.b.yaml_type = 'docker-compose'
  end
end

vim.api.nvim_create_autocmd('BufReadPost', {
  buffer = 0,
  callback = detect_yaml_type,
})
-- }}}1
