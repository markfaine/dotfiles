return {
  'kylechui/nvim-surround',
  event = 'VeryLazy',
  config = function()
    require('nvim-surround').setup {}
    require 'configs.nvim-surround'
  end,
}
