return {
  -- Package management mason and mason-tool-installer
  -- https://github.com/williamboman/mason.nvim
  -- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
  --
  --  Package installer
  {
    'williamboman/mason.nvim',
    cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' },
    lazy = false,
    opts = {
      PATH = 'skip',
      ui = {
        icons = {
          package_pending = ' ',
          package_installed = ' ',
          package_uninstalled = ' ',
        },
      },
      max_concurrent_installers = 10,
    },
  },
  -- Ensure packages (command line tools) are installed
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    config = function()
      require('mason-tool-installer').setup {
        ensure_installed = {
          'autopep8',
          'ansible-language-server',
          'ansible-lint',
          'bash-language-server',
          'black',
          'editorconfig-checker',
          'flake8',
          'glow',
          'gitlab-ci-ls',
          'jinja-lsp',
          'jq',
          'mdformat',
          'prettier',
          'rstcheck',
          'shellcheck',
          'shfmt',
          'pydocstyle',
          'pylint',
          'python-lsp-server',
          'basedpyright',
          'pyflakes',
          'shellcheck',
          'shfmt',
          'sphinx-lint',
          'terraform-ls',
          'tflint',
          'yapf',
          'yamllint',
          'yamlfmt',
          'yq',
        },
      }
    end,
    lazy = false,
  },
  -- linting/tools --  See: https://github.com/jay-babu/mason-null-ls.nvim
  {
    'nvimtools/none-ls.nvim',
    lazy = false,
    config = true,
  },
  {
    'jay-babu/mason-null-ls.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'nvimtools/none-ls.nvim',
    },
    handlers = {
      function() end, -- disables automatic setup of all null-ls sources
      methods = { diagnostics = true }, -- only diagnostic methods

      -- Use yamllint to check yaml files
      yamllint = function(source_name, methods)
        require('mason-null-ls').default_setup(source_name, methods)
      end,

      -- Use rstcheck to check rst files
      rstcheck = function(source_name, methods)
        require('mason-null-ls').default_setup(source_name, methods)
      end,

      -- Use sphinx-lint to check sphinx files
      sphinx_lint = function(source_name, methods)
        require('mason-null-ls').default_setup(source_name, methods)
      end,
    },
    lazy = false,
  },
}
