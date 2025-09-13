return {
  -- Mason core
  {
    'williamboman/mason.nvim',
    cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' },
    lazy = false,
    opts = {
      PATH = 'prepend', -- ensure mason bin comes first
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

  -- Ensure CLI tools and LSP servers
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    lazy = false,
    opts = {
      ensure_installed = {
        -- LSP servers (match your core/lsp.lua)
        'lua-language-server',
        'bash-language-server',
        "gitlab-ci-ls",
        'yaml-language-server',
        'ansible-language-server',
        'marksman',
        'vscode-html-language-server',
        -- Diagnostics via none-ls and ftplugins
        'yamllint',
        'shellcheck',
        'hadolint',
        'markdownlint',
        'rstcheck',
        'sphinx-lint',
        -- Formatters used by Conform
        'stylua',
        'isort',
        'black',
        'shfmt',
        'yamlfmt',
        'mdformat',
      },
      auto_update = true,
      run_on_start = true,
      start_delay = 200,
      debounce_hours = 24,
    },
    config = function(_, opts)
      require('mason-tool-installer').setup(opts)
    end,
  },

  -- none-ls (lazy)
  {
    'nvimtools/none-ls.nvim',
    lazy = true,
    config = true,
  },

  -- mason-null-ls wiring (opt-in diagnostics)
  {
    'jay-babu/mason-null-ls.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'nvimtools/none-ls.nvim',
    },
    opts = {
      automatic_installation = false,
      handlers = {
        function() end, -- no blanket auto-setup

        yamllint = function(source_name, methods)
          require('mason-null-ls').default_setup(source_name, methods)
        end,
        shellcheck = function(source_name, methods)
          require('mason-null-ls').default_setup(source_name, methods)
        end,
        hadolint = function(source_name, methods)
          require('mason-null-ls').default_setup(source_name, methods)
        end,
        markdownlint = function(source_name, methods)
          require('mason-null-ls').default_setup(source_name, methods)
        end,
        rstcheck = function(source_name, methods)
          require('mason-null-ls').default_setup(source_name, methods)
        end,
        sphinx_lint = function(source_name, methods)
          require('mason-null-ls').default_setup(source_name, methods)
        end,
      },
    },
    config = function(_, opts)
      require('mason-null-ls').setup(opts)
    end,
  },
}
