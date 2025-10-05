-- vim: foldmethod=marker foldlevel=1

-- Shared large-file guard
local is_large = function(buf)
  local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
  return ok and stats and stats.size and stats.size > (vim.g.large_file_threshold_bytes or 200*1024)
end
-- use is_large to disable heavy features per buffer

return {
  { -- nvim-treesitter core {{{1
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- use this module for opts

    opts = {
      ensure_installed = {
        'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline',
        'query', 'vim', 'vimdoc', 'regex',
        'yaml', 'json', 'toml', 'python', 'dockerfile', 'hcl',
        'gitcommit', 'gitignore', 'git_rebase', 'gitattributes', 'git_config',
      },
      sync_install = false,
      auto_install = true,

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        disable = function(_, buf) return is_large(buf) end,
      },

      indent = {
        enable = true,
        disable = function(_, buf) return is_large(buf) end,
      },

      incremental_selection = {
        enable = true,
        disable = function(_, buf) return is_large(buf) end,
      },
    },
  },
}
