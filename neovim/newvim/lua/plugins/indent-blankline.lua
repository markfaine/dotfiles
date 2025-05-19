return {
  {
    'lukas-reineke/indent-blankline.nvim',
    lazy = false,
    event = 'User FilePost',
    opts = {
      indent = { char = '│' },
      scope = { char = '│' },
      whitespace = { highlight = { 'Whitespace', 'NonText' }, remove_blankline_trail = true },
    },
    config = function(_, opts)
      local hooks = require 'ibl.hooks'
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
      require('ibl').setup(opts)
    end,
  },
}
