-- vim: foldmethod=marker foldlevel=1

--[[ Core Configuration Documentation {{{1
Core Configuration Module (core/init.lua)

This module serves as the orchestrator for all core Neovim functionality.
It loads and initializes the fundamental components that make up the base
editor experience before any plugins are loaded.

Module Loading Strategy:
-----------------------
- Immediate loading: Essential modules that must be available immediately
- Deferred loading: Modules that can wait until after initialization
- Conditional loading: Modules that depend on specific features/versions
- Error handling: Protected loading with appropriate error reporting
- Performance monitoring: Optional timing information for debugging

Module Descriptions:
-------------------
1. **core.options**: Sets up Neovim's built-in options and settings
   - Editor behavior (tabs, indentation, search, etc.)
   - UI preferences (line numbers, statusline, etc.)
   - Performance settings and optimizations

2. **core.lazy**: Initializes the Lazy.nvim plugin manager
   - Plugin loading and management system
   - Lazy loading configurations for better startup performance
   - Plugin dependency resolution

3. **core.mappings**: Configures keybindings and shortcuts
   - Custom key mappings for enhanced workflow
   - Leader key configurations and mode-specific bindings
   - Deferred to avoid conflicts with built-in mappings

4. **core.autocmds**: Sets up automatic commands and event handlers
   - File type specific behaviors
   - Buffer and window event handling
   - Custom automation for improved editor experience

5. **core.lsp**: Language Server Protocol configuration
   - LSP client setup and server configurations
   - Code intelligence features (completion, diagnostics, etc.)
   - Language-specific tooling integration

6. **core.health**: Health check and diagnostic utilities
   - System compatibility verification
   - Configuration validation
   - Troubleshooting and maintenance tools
}}}1 --]]

-- Module Utilities: safe_require() & config table {{{1
local start_time = vim.g.debug_config and vim.uv.hrtime() or nil

-- Protected module loading with error handling and timing
local function safe_require(module_name, config)
  config = config or {}

  -- Check conditions
  if config.condition and not config.condition() then
    if vim.g.debug_config then
      print(string.format('⏭  %s (skipped - condition not met)', module_name))
    end
    return false
  end

  -- Check if module exists (optional optimization)
  if config.check_exists then
    local module_path = string.gsub(module_name, '%.', '/') .. '.lua'
    local full_path = vim.fn.stdpath 'config' .. '/lua/' .. module_path
    if vim.fn.filereadable(full_path) == 0 then
      if config.required then
        vim.notify(string.format('Required module not found: %s', module_name), vim.log.levels.ERROR)
      end
      return false
    end
  end

  -- Load module with timing
  local module_start = vim.g.debug_config and vim.uv.hrtime() or nil
  local ok, err = pcall(require, module_name)

  if vim.g.debug_config and module_start then
    local duration = (vim.uv.hrtime() - module_start) / 1e6 -- Convert to ms
    local status = ok and '✓' or '✗'
    print(string.format('%s %s (%.2fms)', status, module_name, duration))
  end

  if not ok then
    local level = config.required and vim.log.levels.ERROR or vim.log.levels.WARN
    local message = config.required and 'Failed to load required module' or 'Failed to load optional module'
    vim.notify(string.format('%s %s: %s', message, module_name, err), level)
  end

  return ok
end

-- Module configuration table
local modules = {
  -- Immediate loading (essential)
  {
    name = 'core.options',
    immediate = true,
    required = true,
    description = 'Editor options and settings',
  },
  {
    name = 'core.lazy',
    immediate = true,
    required = false,
    check_exists = true,
    condition = function()
      return vim.fn.isdirectory(vim.fn.stdpath 'config' .. '/lua/plugins') == 1
    end,
    description = 'Plugin manager',
  },

  -- Deferred loading (can wait)
  {
    name = 'core.mappings',
    immediate = false,
    required = true,
    description = 'Key mappings and shortcuts',
  },
  {
    name = 'core.autocmds',
    immediate = false,
    required = false,
    description = 'Auto commands and event handlers',
  },
  {
    name = 'core.lsp',
    immediate = false,
    required = false,
    condition = function()
      return vim.fn.has 'nvim-0.8' == 1
    end,
    description = 'Language Server Protocol setup',
  },

  -- Delayed loading (non-critical)
  {
    name = 'core.health',
    immediate = false,
    required = false,
    delay = 100,
    description = 'Health checks and diagnostics',
  },
}
-- }}}1

-- Load Essential Modules: options & lazy {{{1
if vim.g.debug_config then
  print '🚀 Loading core modules...'
end

for _, module in ipairs(modules) do
  if module.immediate then
    safe_require(module.name, module)
  end
end
-- }}}1

-- Load Deferred Modules: mappings, autocmds, lsp {{{1
vim.schedule(function()
  for _, module in ipairs(modules) do
    if not module.immediate and not module.delay then
      safe_require(module.name, module)
    end
  end

  -- Performance reporting
  if vim.g.debug_config and start_time then
    local deferred_time = (vim.uv.hrtime() - start_time) / 1e6
    print(string.format('⚡ Core modules loaded in %.2fms', deferred_time))
  end
end)
-- }}}1

-- Load Delayed Modules: health checks {{{1
for _, module in ipairs(modules) do
  if module.delay then
    vim.defer_fn(function()
      safe_require(module.name, module)

      if vim.g.debug_config and start_time then
        local total_time = (vim.uv.hrtime() - start_time) / 1e6
        print(string.format('🏁 All core modules loaded in %.2fms', total_time))
      end
    end, module.delay)
  end
end
-- }}}1

-- Global Exports & Compatibility Flags {{{1
-- Expose module loading function for other parts of config
vim.g.core_safe_require = safe_require

-- Set up global flag for successful core loading
vim.g.core_loaded = true
-- }}}1

-- Set snacks to be the default picker {{{1
vim.g.pickme_provider = "snacks"
-- }}}1

-- Call user commands {{{1
pcall(require, 'after.plugin.commands')
-- }}}1
