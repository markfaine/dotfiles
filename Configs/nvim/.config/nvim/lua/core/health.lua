-- This file is not required but helps diagnose issues with your Neovim

-- vim: foldmethod=marker foldlevel=1

--[[ Health Check Module {{{1
Comprehensive health checks for Neovim configuration validation.
}}}1 --]]

-- Version Validation {{{1
local function check_neovim_version()
  vim.health.start('Neovim Version')

  local version = vim.version()
  local version_str = tostring(version)

  if not vim.version.ge then
    vim.health.error('vim.version.ge function not available - very old Neovim version')
    return false
  end

  local min_version = vim.version.parse('0.10.0')
  local recommended = vim.version.parse('0.11.0')

  if vim.version.ge(version, recommended) then
    vim.health.ok(string.format('Neovim version: %s ✓', version_str))
  elseif vim.version.ge(version, min_version) then
    vim.health.warn(string.format('Neovim version: %s (consider upgrading)', version_str))
  else
    vim.health.error(string.format('Neovim version: %s (too old)', version_str))
    return false
  end

  return true
end
-- }}}1

-- System Dependencies {{{1
local function check_system_dependencies()
  vim.health.start('System Dependencies')

  local essential = { 'git', 'curl', 'unzip' }
  local optional = { 'make', 'gcc', 'node', 'python3', 'rg', 'fd' }

  local essential_missing = {}
  for _, tool in ipairs(essential) do
    if vim.fn.executable(tool) == 1 then
      vim.health.ok(string.format('Essential: %s ✓', tool))
    else
      vim.health.error(string.format('Essential: %s ✗', tool))
      table.insert(essential_missing, tool)
    end
  end

  for _, tool in ipairs(optional) do
    if vim.fn.executable(tool) == 1 then
      vim.health.ok(string.format('Optional: %s ✓', tool))
    else
      vim.health.info(string.format('Optional: %s (not found)', tool))
    end
  end

  return #essential_missing == 0
end
-- }}}1

-- LSP Validation {{{1
local function check_lsp_servers()
  vim.health.start('Language Servers')

  if not vim.lsp then
    vim.health.error('LSP not available')
    return false
  end

  vim.health.ok('LSP client available ✓')

  local servers = {
    { 'lua-language-server', 'Lua' },
    { 'bash-language-server', 'Bash' },
    { 'pylsp', 'Python' },
    { 'yaml-language-server', 'YAML' },
  }

  for _, server in ipairs(servers) do
    if vim.fn.executable(server[1]) == 1 then
      vim.health.ok(string.format('%s: %s ✓', server[2], server[1]))
    else
      vim.health.info(string.format('%s: %s (not found)', server[2], server[1]))
    end
  end

  return true
end
-- }}}1

-- Configuration Validation {{{1
local function check_configuration()
  vim.health.start('Configuration')

  local modules = { 'core.options', 'core.mappings', 'core.autocmds', 'core.lazy', 'core.lsp' }
  for _, module in ipairs(modules) do
    local ok = pcall(require, module)
    if ok then
      vim.health.ok(string.format('Module: %s ✓', module))
    else
      vim.health.error(string.format('Module: %s ✗', module))
    end
  end

  -- Check key settings
  if vim.g.mapleader then
    vim.health.ok(string.format('Leader key: "%s" ✓', vim.g.mapleader))
  else
    vim.health.warn('Leader key: not set')
  end

  if vim.g.core_loaded then
    vim.health.ok('Core configuration: loaded ✓')
  else
    vim.health.warn('Core configuration: not confirmed loaded')
  end

  return true
end
-- }}}1

-- Performance Check {{{1
local function check_performance()
  vim.health.start('Performance')

  local memory_kb = vim.fn.luaeval('collectgarbage("count")')
  local memory_mb = memory_kb / 1024

  if memory_mb < 20 then
    vim.health.ok(string.format('Memory usage: %.1f MB ✓', memory_mb))
  else
    vim.health.warn(string.format('Memory usage: %.1f MB (high)', memory_mb))
  end

  -- Check performance-related options
  local opts = {
    { 'updatetime', vim.o.updatetime, 300 },
    { 'timeoutlen', vim.o.timeoutlen, 500 },
  }

  for _, opt in ipairs(opts) do
    if opt[2] <= opt[3] then
      vim.health.ok(string.format('%s: %d ✓', opt[1], opt[2]))
    else
      vim.health.info(string.format('%s: %d (could be optimized)', opt[1], opt[2]))
    end
  end

  return true
end
-- }}}1

-- Main Health Check Function {{{1
return {
  check = function()
    vim.health.start('Neovim Configuration Health Check')

    vim.health.info([[
NOTE: Not every warning requires immediate action.
Focus on errors and warnings for features you actively use.
Optional tools can be installed as needed for specific workflows.
    ]])

    -- System information
    local uv = vim.uv or vim.loop
    local system_info = uv.os_uname()
    vim.health.info(string.format('System: %s %s (%s)', system_info.sysname, system_info.release, system_info.machine))

    -- Run all health checks
    local checks = {
      check_neovim_version,
      check_system_dependencies,
      check_lsp_servers,
      check_configuration,
      check_performance,
    }

    local all_passed = true
    for _, check_fn in ipairs(checks) do
      local ok, result = pcall(check_fn)
      if not ok then
        vim.health.error(string.format('Health check failed: %s', result))
        all_passed = false
      elseif result == false then
        all_passed = false
      end
    end

    -- Summary
    vim.health.start('Summary')
    if all_passed then
      vim.health.ok('All critical checks passed! 🎉')
    else
      vim.health.warn('Some checks failed - review the output above')
    end

    vim.health.info('Run :checkhealth for additional plugin-specific checks')
  end,
}
-- }}}1
