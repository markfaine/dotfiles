-- Filetype configuration for .yaml/.yml

-- Never use actual tab characters, and tab is 4 spaces
vim.opt.shiftwidth = 2
vim.opt.smarttab = true
vim.opt.expandtab = true

-- if the filename is '.yml' set the type to yaml
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = '*.yml',
  callback = function()
    vim.bo.filetype = 'yaml'
  end,
})

-- if the filename is 'gitlab-ci.yml' set the type to yaml.gitlab
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = '*.gitlab-ci*.{yml,yaml}',
  callback = function()
    vim.bo.filetype = 'yaml.gitlab'
  end,
})
