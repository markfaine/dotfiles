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
      add_default_keybindings = true,
    },
    keys = {
      {
        '<leader>ff',
        function()
          require('pickme').pick('git_files', { title = 'Git Files' })
        end,
        desc = 'Git Files',
        mode = 'n',
      },
      {
        '<leader>fg',
        function()
          require('pickme').pick('live_grep', { title = 'Live Grep' })
        end,
        desc = 'Live Grep',
      },
      { '<leader>fa', '<cmd>PickMe files<cr>', desc = 'All files' },
      {
        '<leader>fb',
        function()
          require('pickme').pick('buffers', { title = 'Buffers' })
        end,
        desc = 'Buffers',
      },
    },
  },
}
