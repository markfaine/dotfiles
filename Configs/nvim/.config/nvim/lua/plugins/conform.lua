-- vim: foldmethod=marker foldlevel=1

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  keys = {
    { '<leader>bf', function() require('conform').format({ async = true, lsp_format = 'prefer' }) end, desc = 'Format buffer' },
    { '<leader>bF', function() require('conform').format({ async = false, timeout_ms = 2000, lsp_format = 'prefer' }) end, desc = 'Format buffer (sync)' },
  },
  config = function()
    local conform = require('conform')

    local function is_large(bufnr)
      local fs = (vim.uv or vim.loop).fs_stat
      local name = vim.api.nvim_buf_get_name(bufnr)
      local ok, stat = pcall(fs, name)
      local limit = vim.g.large_file_threshold_bytes or 200 * 1024
      return ok and stat and stat.size > limit
    end

    conform.setup({
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        sh = { 'shfmt' },
        yaml = { 'yamlfmt' },
        markdown = { 'mdformat' },
        ['_'] = {}, -- default none
      },
      -- prefer LSP if available, otherwise fall back to tool
      format_on_save = function(bufnr)
        if is_large(bufnr) then return end
        return { lsp_format = 'prefer', timeout_ms = 1000 }
      end,
    })

    -- Simple enable/disable/toggle
    local enabled = true
    vim.api.nvim_create_user_command('FormatEnable', function() enabled = true end, { desc = 'Enable format_on_save' })
    vim.api.nvim_create_user_command('FormatDisable', function() enabled = false end, { desc = 'Disable format_on_save' })
    vim.api.nvim_create_user_command('FormatToggle', function() enabled = not enabled end, { desc = 'Toggle format_on_save' })

    -- Respect toggles
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = vim.api.nvim_create_augroup('ConformAutosave', { clear = true }),
      callback = function(args)
        if not enabled or is_large(args.buf) then return end
        conform.format({ bufnr = args.buf, lsp_format = 'prefer', timeout_ms = 1000 })
      end,
    })
  end,
}
