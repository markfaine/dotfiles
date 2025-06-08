return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>bf',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        css = { 'prettier', lsp_format = 'fallback' },
        html = { 'prettier', lsp_format = 'fallback' },
        javascript = { 'prettier', lsp_format = 'fallback' },
        lua = { 'stylua', lsp_format = 'fallback' },
        md = { name = 'mdformat', lsp_format = 'fallback' },
        -- python = { "isort", "black", lsp_fallback = "fallback" },
        sh = { 'shfmt', lsp_format = 'fallback' },
        yaml = { 'yamlfmt', lsp_format = 'prefer' },
      },
      formatters = {
        shfmt = {
          inherit = false,
          command = 'shfmt',
          args = { '-i', '4' },
        },
        black = {
          inherit = true,
          prepend_args = {
            '--line-length',
            '180',
            '-t',
            'py310',
            '-t',
            'py311',
            '-t',
            'py312',
            '-t',
            'py313',
          },
        },
        yamlfmt = {
          args = { '--formatter', 'indent=2,retain_line_breaks_single=true' },
        },
      },
    },
  },
}
