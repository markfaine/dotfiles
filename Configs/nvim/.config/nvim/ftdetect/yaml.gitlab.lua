-- vim: foldmethod=marker foldlevel=1

--[[ GitLab CI YAML filetype detection {{{1
Detects GitLab CI configuration files by common paths and content.
Avoids overriding other YAML specializations (Ansible, Kubernetes, Compose).
Sets filetype to 'yaml.gitlab' to enable dedicated tooling/LSP.
}}}1 --]]

local grp = vim.api.nvim_create_augroup('GitLabCiFtdetect', { clear = true })

-- Helpers {{{1
local function can_set_ft()
  local ft = vim.bo.filetype
  return ft == '' or ft == 'yaml' -- don’t override yaml.ansible, yaml.kubernetes, etc.
end

local function looks_like_k8s(s)
  s = s:lower()
  return s:find('\napiversion:%s*') or s:find('\nkind:%s*')
end

local function looks_like_ansible(s)
  s = s:lower()
  return s:find('\nhosts:%s*') or s:find('\ntasks:%s*') or s:find('\nroles:%s*') or s:find('ansible_')
end

local function looks_like_compose(s)
  s = s:lower()
  return s:find('\nversion:%s*') and s:find('\nservices:%s*')
end

local function looks_like_gitlab(s)
  s = s:lower()
  -- Typical GitLab CI keys; any of these strongly indicate a pipeline file
  return s:find('\nstages:%s*')
      or s:find('\nworkflow:%s*')
      or s:find('\nvariables:%s*')
      or s:find('\ninclude:%s*')
      or s:find('\nrules:%s*')
      or s:find('\nimage:%s*')
      or s:find('\ncache:%s*')
      or s:find('\nscript:%s*')
end
-- }}}1

-- Path-based detection (most reliable) {{{1
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  group = grp,
  pattern = {
    '*/.gitlab-ci.yml',
    '*/.gitlab-ci.yaml',
    '*/.gitlab-ci-*.yml',
    '*/.gitlab-ci-*.yaml',
    '*/.gitlab/ci/*.yml',
    '*/.gitlab/ci/*.yaml',
  },
  callback = function()
    if not can_set_ft() then return end
    vim.bo.filetype = 'yaml.gitlab'
    vim.b.yaml_type = 'gitlab'
    vim.b.gitlab_ci = true
  end,
})
-- }}}1

-- Content-based detection (fallback for arbitrary YAML) {{{1
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  group = grp,
  pattern = { '*.yml', '*.yaml' },
  callback = function()
    if not can_set_ft() then return end

    local max_lines = math.min(80, vim.api.nvim_buf_line_count(0))
    local lines = vim.api.nvim_buf_get_lines(0, 0, max_lines, false)
    local content = '\n' .. table.concat(lines, '\n') .. '\n'

    -- Avoid common false positives first
    if looks_like_k8s(content) or looks_like_ansible(content) or looks_like_compose(content) then
      return
    end

    if looks_like_gitlab(content) then
      vim.bo.filetype = 'yaml.gitlab'
      vim.b.yaml_type = 'gitlab'
      vim.b.gitlab_ci = true
    end
  end,
})
-- }}}1
