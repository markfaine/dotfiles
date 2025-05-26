return {
  -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
  -- used for completion, annotations and signatures of Neovim apis
  -- Choose a picker based on what's available
  {
    '2KAbhishek/pickme.nvim',
    cmd = 'PickMe',
    event = 'VeryLazy',
    dependencies = {
      -- Include at least one of these pickers:
      'folke/snacks.nvim', -- For snacks.picker
      -- 'nvim-telescope/telescope.nvim', -- For telescope
      -- 'ibhagwan/fzf-lua', -- For fzf-lua
    },
    opts = {
      picker_provider = 'snacks', -- Default provider
    },
  },
}
