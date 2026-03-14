-- vim: foldmethod=marker foldlevel=1
pcall(function() vim.loader.enable() end)

--[[ Neovim Configuration Entry Point (init.lua) {{{1


This file serves as the main entry point for Neovim's Lua-based configuration system.
When Neovim starts, it automatically looks for and loads this file from your configuration
directory (~/.config/nvim).

How Neovim Lua Configuration Works:
----------------------------------

1. **Configuration Loading Order**:
   - Neovim first loads init.lua (this file)
   - This file then requires other Lua modules to set up the complete configuration
   - The 'require' function loads Lua modules from the lua/ directory

2. **Module Structure**:
   - The lua/ directory contains organized modules for different aspects of configuration
   - Each .lua file or directory with init.lua becomes a loadable module
   - For example: lua/core/init.lua can be loaded with require('core')

3. **What 'require' Does**:
   - require('core') loads and executes the lua/core/init.lua file
   - This sets up core Neovim functionality like options, keymaps, autocommands, etc.
   - The core module likely requires other modules to build the complete configuration

4. **Benefits of This Approach**:
   - Modular: Configuration is split into logical, manageable pieces
   - Reusable: Modules can be easily shared or moved between configurations
   - Maintainable: Each aspect of configuration has its own file/directory
   - Extensible: New features can be added by creating new modules

5. **Common Configuration Modules**:
   - core/: Basic Neovim settings (options, keymaps, autocommands)
   - plugins/: Plugin configurations and setups
   - configs/: Specific tool or language configurations
   - after/: Configuration that runs after built-in plugins load

This minimalist init.lua demonstrates the "single point of entry" pattern where
all configuration complexity is organized in the lua/ directory structure.
}}}1 --]]

-- Core Module Loading {{{1
require 'core'
-- }}}1
