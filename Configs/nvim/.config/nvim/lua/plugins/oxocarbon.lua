return {
  'nyoom-engineering/oxocarbon.nvim',
  lazy = false,
  priority = 100000,
  config = function()
    vim.opt.background = 'dark' -- set this to dark or light
    vim.cmd.colorscheme 'oxocarbon'
  end,
}
