return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- uncomment for format on save
    config = function()
      require "configs.conform"
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "tree-sitter",
        "black",
        "mypy",
        "ruff",
        "shellcheck",
        "shfmt",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "pylsp",
        "pyright",
        "bashls",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },
}
