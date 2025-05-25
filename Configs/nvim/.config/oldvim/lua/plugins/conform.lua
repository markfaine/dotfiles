return {
  "stevearc/conform.nvim",
  config = function()
    --  Key mappings
    keys = { { "<leader>fm", 'require("conform").format()', desc = "Format (general)" } }
    require("conform").setup {
      formatters_by_ft = {
        css = { "prettier", lsp_format = "fallback" },
        html = { "prettier", lsp_format = "fallback" },
        javascript = { "prettier", lsp_format = "fallback" },
        lua = { "stylua", lsp_format = "fallback" },
        md = { name = "mdformat", lsp_format = "fallback" },
        -- python = { "isort", "black", lsp_fallback = "fallback" },
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

    -- python
    require("conform").formatters.black = {
      inherit = true,
      prepend_args = {
        "--line-length",
        "180",
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
}
