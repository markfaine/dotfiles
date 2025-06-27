return {
  'L3MON4D3/LuaSnip',
  build = 'make install_jsregexp',
  dependencies = {
    'hrsh7th/nvim-cmp',
  },
  config = function()
    require 'luasnip'
    --require('luasnip-snippets').load_snippets()
  end,
}
