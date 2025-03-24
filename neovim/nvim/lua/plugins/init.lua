return {
  -- Ansible (filetype)
  {
    "mfussenegger/nvim-ansible",
    lazy = false,
  },
  -- formatting
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup {
        formatters_by_ft = {
          css = { "prettier", lsp_format = "fallback" },
          html = { "prettier", lsp_format = "fallback" },
          javascript = { "prettier", lsp_format = "fallback" },
          lua = { "stylua", lsp_format = "fallback" },
          md = { name = "mdformat", lsp_format = "fallback" },
          python = { "black", lsp_fallback = "fallback" },
          sh = { "shfmt", lsp_format = "fallback" },
          yaml = { "yamlfmt", lsp_format = "prefer" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = "never",
        },
      }

      require("conform").formatters.shfmt = {
        inherit = false,
        command = "shfmt",
        args = { "-i", "4" },
      }

      require("conform").formatters.black = {
        inherit = true,
        prepend_args = {
          "--line-length",
          "79",
          "-t",
          "py310",
          "-t",
          "py311",
          "-t",
          "py312",
          "-t",
          "py313",
        },
      }

      require("conform").formatters.yamlfmt = {
        args = { "--formatter", "indent=2,retain_line_breaks_single=true" },
      }
    end,
    lazy = false,
  },
  -- LSP/package management
  {
    "williamboman/mason.nvim",
    opts = {},
    lazy = false,
  },
  -- LSP
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require "configs.lspconfig"
    end,
    automatic_installation = true,
    lazy = false,
  },
  -- LSP
  {
    "neovim/nvim-lspconfig",
    opts = {},
    lazy = false,
  },
  -- linting/tools
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    },
    config = function()
      require "configs.none-ls"
    end,
    lazy = false,
  },
  -- package management
  {
    "kdheepak/lazygit.nvim",
    lazy = false,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require "configs.lazygit"
    end,
  },
  -- git tui
  {
    "amitds1997/remote-nvim.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = true,
  },
  -- git diff
  {
    "sindrets/diffview.nvim",
    lazy = false,
    config = function()
      require "configs.diffview"
    end,
  },
  -- package management
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup {
        ensure_installed = {
          "autopep8",
          "ansible-language-server",
          "ansible-lint",
          "bashls",
          "black",
          "editorconfig-checker",
          "flake8",
          "glow",
          "jinja-lsp",
          "jq",
          "mdformat",
          "prettier",
          "rstcheck",
          "shellcheck",
          "shfmt",
          "pydocstyle",
          "pylint",
          "pylsp",
          "pyflakes",
          "shellcheck",
          "shfmt",
          "sphinx-lint",
          "terraform-ls",
          "tflint",
          "yapf",
          "yamllint",
          "yamlfmt",
          "yq",
        },
      }
    end,
    lazy = false,
  },
  -- key mapping
  {
    "folke/which-key.nvim",
    lazy = false,
  },
  -- docstring generator
  {
    "kkoomen/vim-doge",
    config = function()
      require "configs.vim-doge"
    end,
    lazy = false,
  },
  -- improved copy/paste
  { "ibhagwan/smartyank.nvim", lazy = false },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      require "configs.snacks"
    end,
  },
}
