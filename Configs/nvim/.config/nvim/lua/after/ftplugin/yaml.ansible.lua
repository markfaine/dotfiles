-- vim: foldmethod=marker foldlevel=1

--[[ YAML Ansible Configuration {{{1
Ansible-specific enhancements for YAML files.
Inherits base YAML configuration and adds Ansible tooling.
}}}1 --]]

-- Load base YAML configuration
require('after.ftplugin.yaml')

-- Ansible-Specific Settings {{{1
-- Override some settings for Ansible playbooks
vim.opt_local.textwidth = 120  -- Ansible playbooks can be wider
vim.opt_local.colorcolumn = '121'
vim.opt_local.foldlevel = 2    -- Show more Ansible structure by default

-- Set buffer variable for type detection
vim.b.yaml_type = 'ansible'
-- }}}1

-- Ansible-Specific Mappings {{{1
-- Quick Ansible task creation
vim.keymap.set('i', '<C-t>', function()
  local line = vim.api.nvim_get_current_line()
  local indent = line:match('^%s*')
  return '- name: \n' .. indent .. '  '
end, { buffer = true, expr = true, desc = 'Create Ansible task' })

-- Quick module insertion
vim.keymap.set('i', '<C-m>', function()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()

  -- Common Ansible modules
  local modules = {
    'copy', 'template', 'file', 'lineinfile', 'replace',
    'shell', 'command', 'script', 'debug',
    'package', 'yum', 'apt', 'pip',
    'service', 'systemd', 'cron',
    'user', 'group', 'mount',
    'git', 'unarchive', 'get_url',
    'stat', 'assert', 'fail', 'set_fact'
  }

  vim.ui.select(modules, {
    prompt = 'Select Ansible module:',
    format_item = function(item) return item end,
  }, function(choice)
    if choice then
      vim.api.nvim_set_current_line(line .. choice .. ': ')
      vim.api.nvim_win_set_cursor(0, { cursor_pos[1], #line + #choice + 2 })
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert Ansible module' })

-- Smart handler creation
vim.keymap.set('i', '<C-h>', function()
  local indent = string.rep(' ', vim.fn.indent('.'))
  return '- name: \n' .. indent .. '  listen: ""'
end, { buffer = true, expr = true, desc = 'Create Ansible handler' })

-- Ansible-specific navigation (override base YAML navigation)
vim.keymap.set('n', ']]', '/^\\s*- name:\\|^\\s*hosts:\\|^\\s*- hosts:<CR>',
  { buffer = true, desc = 'Next Ansible task/play' })
vim.keymap.set('n', '[[', '?^\\s*- name:\\|^\\s*hosts:\\|^\\s*- hosts:<CR>',
  { buffer = true, desc = 'Previous Ansible task/play' })
-- }}}1

-- Ansible Validation and Tools {{{1
local function validate_ansible()
  local current_file = vim.fn.expand('%:p')

  if vim.fn.executable('ansible-lint') == 1 then
    local result = vim.fn.system('ansible-lint --parseable-severity ' .. current_file)
    if vim.v.shell_error == 0 then
      vim.notify('✓ Ansible playbook is valid', vim.log.levels.INFO)
    else
      vim.notify('✗ Ansible lint issues:\n' .. result, vim.log.levels.ERROR)
    end
  elseif vim.fn.executable('ansible-playbook') == 1 then
    local result = vim.fn.system('ansible-playbook --syntax-check ' .. current_file)
    if vim.v.shell_error == 0 then
      vim.notify('✓ Ansible syntax is valid', vim.log.levels.INFO)
    else
      vim.notify('✗ Ansible syntax errors:\n' .. result, vim.log.levels.ERROR)
    end
  else
    vim.notify('Neither ansible-lint nor ansible-playbook available', vim.log.levels.WARN)
  end
end

local function encrypt_string()
  if vim.fn.executable('ansible-vault') == 0 then
    vim.notify('ansible-vault not available', vim.log.levels.ERROR)
    return
  end

  vim.ui.input({ prompt = 'Enter string to encrypt: ' }, function(input)
    if input and input ~= '' then
      local result = vim.fn.system('ansible-vault encrypt_string --stdin-name "encrypted_var"', input)
      if vim.v.shell_error == 0 then
        vim.api.nvim_put(vim.split(result, '\n'), 'l', true, true)
      else
        vim.notify('Failed to encrypt string', vim.log.levels.ERROR)
      end
    end
  end)
end

local function ansible_docs()
  vim.ui.input({ prompt = 'Module name: ' }, function(module)
    if module and module ~= '' then
      if vim.fn.executable('ansible-doc') == 1 then
        vim.cmd('split')
        vim.cmd('terminal ansible-doc ' .. module)
      else
        vim.notify('ansible-doc not available', vim.log.levels.ERROR)
      end
    end
  end)
end

-- Ansible-specific tool mappings (prefix with 'a' for ansible)
vim.keymap.set('n', '<leader>av', validate_ansible, { buffer = true, desc = 'Validate Ansible' })
vim.keymap.set('n', '<leader>ae', encrypt_string, { buffer = true, desc = 'Encrypt with ansible-vault' })
vim.keymap.set('n', '<leader>ad', ansible_docs, { buffer = true, desc = 'Ansible module docs' })
-- }}}1

-- Ansible Auto Commands {{{1
-- Auto-completion for Jinja2 expressions
vim.api.nvim_create_autocmd('InsertCharPre', {
  buffer = 0,
  callback = function()
    if vim.v.char == '{' then
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]

      -- If we're starting a Jinja2 expression
      if col > 0 and line:sub(col, col) == '{' then
        vim.schedule(function()
          vim.api.nvim_feedkeys(' ', 'n', true)
          vim.api.nvim_feedkeys(' }}', 'n', true)
          vim.api.nvim_feedkeys(string.rep('\b', 3), 'n', true)
        end)
      end
    end
  end,
  desc = 'Auto-complete Jinja2 expressions'
})

-- Ansible context detection for status line
vim.api.nvim_create_autocmd('BufEnter', {
  buffer = 0,
  callback = function()
    local file_path = vim.fn.expand('%:p')
    local dir_name = vim.fn.fnamemodify(file_path, ':h:t')

    if dir_name == 'tasks' or dir_name == 'handlers' then
      vim.b.ansible_context = 'Role: ' .. vim.fn.fnamemodify(file_path, ':h:h:t')
    elseif vim.fn.expand('%:t'):match('playbook') then
      vim.b.ansible_context = 'Playbook'
    else
      vim.b.ansible_context = 'Ansible'
    end
  end,
  desc = 'Set Ansible context for status line'
})
-- }}}1
