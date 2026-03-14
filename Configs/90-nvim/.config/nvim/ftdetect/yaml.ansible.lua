-- vim: foldmethod=marker foldlevel=1

--[[ Ansible YAML filetype detection {{{1
Detect Ansible files by path and content while avoiding common false positives.
Sets filetype to 'yaml.ansible' and annotates buffer with yaml_type/ansible flags.
}}}1 --]]

local grp = vim.api.nvim_create_augroup('AnsibleFtdetect', { clear = true })

-- Helpers {{{1
local function can_set_ft()
  local ft = vim.bo.filetype
  return ft == '' or ft == 'yaml' -- don’t override other yaml.* specializations
end

local function looks_like_k8s(s)
  s = s:lower()
  return s:find('\nkind:%s*') or s:find('\napiversion:%s*')
end

local function looks_like_gitlab(s, fname)
  s = s:lower()
  return (fname and fname:match('%.gitlab%-ci%.ya?ml$')) or s:find('\nstages:%s*')
end

local function looks_like_ansible(s)
  -- Heuristics: hosts/play/tasks/roles/become/ansible_ vars, gather_facts, and common task forms
  return s:find('\nhosts:%s*')
    or s:find('\ntasks:%s*')
    or s:find('\nroles:%s*')
    or s:find('\nbecome:%s*')
    or s:find('ansible_')
    or s:find('\ngather_facts:%s*')
    or s:find('\n%-+%s*name:%s*') -- task name lines
end
-- }}}1

-- Path-based detection {{{1
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  group = grp,
  pattern = {
    -- Playbooks
    '*/playbooks/*.yml',
    '*/playbooks/*.yaml',
    '*/*playbook*.yml',
    '*/*playbook*.yaml',
    '*/site.yml',
    '*/site.yaml',

    -- Roles (common subdirs)
    '*/roles/*/tasks/*.yml',
    '*/roles/*/tasks/*.yaml',
    '*/roles/*/handlers/*.yml',
    '*/roles/*/handlers/*.yaml',
    '*/roles/*/defaults/*.yml',
    '*/roles/*/defaults/*.yaml',
    '*/roles/*/vars/*.yml',
    '*/roles/*/vars/*.yaml',
    '*/roles/*/meta/*.yml',
    '*/roles/*/meta/*.yaml',

    -- Inventory vars
    '*/group_vars/*.yml',
    '*/group_vars/*.yaml',
    '*/host_vars/*.yml',
    '*/host_vars/*.yaml',

    -- Molecule scenarios
    '*/molecule/*/*.yml',
    '*/molecule/*/*.yaml',
  },
  callback = function(args)
    if not can_set_ft() then return end
    vim.bo.filetype = 'yaml.ansible'
    vim.b.yaml_type = 'ansible'
    vim.b.ansible_detected = true
  end,
})
-- }}}1

-- Content-based detection (fallback/loose) {{{1
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  group = grp,
  pattern = { '*.yml', '*.yaml' },
  callback = function(args)
    if not can_set_ft() then return end

    local fname = vim.api.nvim_buf_get_name(0)
    local lines = vim.api.nvim_buf_get_lines(0, 0, math.min(50, vim.api.nvim_buf_line_count(0)), false)
    local content = ('\n' .. table.concat(lines, '\n') .. '\n'):gsub('\r', '')

    -- Avoid false positives first
    if looks_like_k8s(content) or looks_like_gitlab(content, fname) then
      return
    end

    if looks_like_ansible(content) then
      vim.bo.filetype = 'yaml.ansible'
      vim.b.yaml_type = 'ansible'
      vim.b.ansible_detected = true
    end
  end,
})
-- }}}1

-- Inherit base YAML settings
vim.b.yaml_is_ansible = true

-- Ansible-centric edits
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Handy mappings
vim.keymap.set('n', '<leader>al', '<cmd>!ansible-lint %<cr>', { buffer = true, desc = 'ansible-lint current file' })
vim.keymap.set('n', '<leader>ad', '<cmd>!ansible-doc -l | less<cr>', { buffer = true, desc = 'ansible-doc list' })

-- Vault helpers
vim.keymap.set('n', '<leader>av', '<cmd>!ansible-vault view %<cr>', { buffer = true, desc = 'ansible-vault view' })
