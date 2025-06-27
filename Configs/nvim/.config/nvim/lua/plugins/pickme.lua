--local pickme = require 'pickme'
return {
  -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
  -- used for completion, annotations and signatures of Neovim apis
  -- Choose a picker based on what's available
  {
    '2KAbhishek/pickme.nvim',
    cmd = 'PickMe',
    event = 'VeryLazy',
    dependencies = {
      'folke/snacks.nvim', -- For snacks.picker
    },
    opts = {
      picker_provider = 'snacks', -- Default provider
      add_default_keybindings = true,
      --pickme.pick('autocmds', { title = 'List autocommands' }),
    },
  },
}
