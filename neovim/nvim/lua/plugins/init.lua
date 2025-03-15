return {
  {
    "mfussenegger/nvim-ansible",
    lazy = false,
  },
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
          python = { "isort", "black", lsp_fallback = "fallback" },
          sh = { "shfmt", lsp_format = "fallback" },
          yaml = { "yamlfmt", lsp_format = "prefer" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = "fallback",
        },
      }

      require("conform").formatters.shfmt = {
        inherit = false,
        command = "shfmt",
        args = { "-i", "4" },
      }

      require("conform").formatters.yamlfmt = {
        args = { "--formatter", "indent=2,retain_line_breaks_single=true" },
      }
    end,
    lazy = false,
  },
  -- LSP
  {
    "williamboman/mason.nvim",
    lazy = false,
  },
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
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require "configs.lspconfig"
    end,
    lazy = false,
  },
  {
    "neovim/nvim-lspconfig",
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup {
        ensure_installed = {
          "ansible-language-server",
          "ansible-lint",
          "bashls",
          "black",
          "editorconfig-checker",
          "glow",
          "isort",
          "jinja-lsp",
          "jq",
          "mdformat",
          "mypy",
          "prettier",
          "rstcheck",
          "shellcheck",
          "shfmt",
          "pylsp",
          "pyright",
          "ruff",
          "shellcheck",
          "shfmt",
          "sphinx-lint",
          "terraform-ls",
          "tflint",
          "yamllint",
          "yamlfmt",
          "yamlfix",
          "yq",
        },
      }
    end,
    lazy = false,
  },
  {
    "folke/which-key.nvim",
    lazy = false,
  },
}
