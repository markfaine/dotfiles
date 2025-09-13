-- vim: foldmethod=marker foldlevel=1

return {
  'folke/which-key.nvim',
  event = 'VeryLazy', -- defer UI helper

  -- Register real keymaps via Lazy (fixes the error)
  keys = {
    { '<leader>lF', '<cmd>LspFormatToggle<CR>', mode = 'n', desc = 'Toggle Autoformat' },
  },

  opts = {
    -- UX {{{2
    delay = 0,
    preset = 'modern',
    show_help = true,
    -- }}}2

    -- Window & layout {{{2
    win = {
      border = 'rounded',
      no_overlap = true,
      zindex = 60,
      padding = { 1, 2 },
      title = 'which-key — help: <leader>?', -- indicate help key in the title
      title_pos = 'center',
    },
    layout = {
      height = { min = 4, max = 25 },
      width = { min = 20, max = 50 },
      spacing = 3,
      align = 'left',
    },
    sort = { 'locality', 'order', 'group' },
    -- }}}2

    -- Triggers (keep automatic; limit to normal/visual/operator) {{{2
    triggers = {
      { '<auto>', mode = { 'n', 'x', 'o' } },
    },
    -- }}}2
  },

  config = function(_, opts)
    local ok, wk = pcall(require, 'which-key')
    if not ok then
      return
    end
    wk.setup(opts)

    -- Register common <leader> groups once {{{2
    local groups_add = {
      { '<leader>b', group = 'buffers' },
      { '<leader>c', group = 'code' },
      { '<leader>d', group = 'diagnostics' },
      { '<leader>f', group = 'file/find' },
      { '<leader>g', group = 'git' },
      { '<leader>h', group = 'hunks' },
      { '<leader>?', group = 'help [?]' }, -- make the help key obvious
      { '<leader>l', group = 'LSP' },
      { '<leader>s', group = 'search' },
      { '<leader>t', group = 'toggle/term/test' },
      { '<leader>tf', group = 'format' },
      { '<leader>w', group = 'windows' },
      { '<leader>y', group = 'yaml/tools' },
    }

    -- Actual help shortcut: show WhichKey
    local help_shortcut = {
      { '<leader>?', '<cmd>WhichKey<CR>', desc = 'Show keymaps (which-key)' },
    }

    if wk.add then
      wk.add(groups_add, { mode = 'n', silent = true })
      wk.add(help_shortcut, { mode = 'n', silent = true })
    else
      wk.register({
        ['<leader>?'] = { '<cmd>WhichKey<CR>', 'Show keymaps (which-key)' }, -- help key visible
      }, { mode = 'n', silent = true })
    end
    -- }}}2

    -- Fold mappings {{{2
    local ok2, wk2 = pcall(require, 'which-key')
    if ok2 and wk2.add then
      wk2.add({
        { 'z', group = 'folds' },
        {
          'zR',
          function()
            local u_ok, u = pcall(require, 'ufo')
            if u_ok then
              u.openAllFolds()
            else
              vim.cmd 'normal! zR'
            end
          end,
          desc = 'Open all folds',
        },
        {
          'zM',
          function()
            local u_ok, u = pcall(require, 'ufo')
            if u_ok then
              u.closeAllFolds()
            else
              vim.cmd 'normal! zM'
            end
          end,
          desc = 'Close all folds',
        },
      }, { mode = 'n', silent = true })
    end
    -- }}}2
  end,
}
