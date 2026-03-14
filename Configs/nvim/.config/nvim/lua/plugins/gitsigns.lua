-- vim: foldmethod=marker foldlevel=1

--[[ Gitsigns Configuration {{{1
Lean, fast setup for gutter signs and hunk actions with sensible defaults.

Highlights:
- Lazy-load on buffer open (BufReadPre/BufNewFile)
- Light visuals (no numhl/linehl), debounced updates
- Skip huge/untracked files for performance
- Blame disabled by default; toggle via mapping
}}}1 --]]

return {
  { -- gitsigns.nvim {{{1
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' }, -- load only when a buffer is opened
    opts = { -- Options {{{2
      -- Visuals {{{3
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      sign_priority = 5,
      numhl = false,
      linehl = false,
      word_diff = false,
      preview_config = { border = 'rounded' },
      -- }}}3

      -- Performance {{{3
      attach_to_untracked = false,                -- don’t scan untracked by default
      max_file_length = 300000,                   -- skip very large files (~300 KB)
      update_debounce = 100,                      -- throttle updates
      watch_gitdir = { interval = 1000, follow_files = true }, -- lower watcher frequency
      -- NOTE: The 'yadm' option was removed upstream; keeping it causes:
      -- "ignoring invalid configuration field 'yadm'". If you rely on yadm,
      -- pin gitsigns to an older commit that still supports it.
      -- }}}3

      -- Blame (off by default; toggle via mapping) {{{3
      current_line_blame = false,
      current_line_blame_opts = {
        delay = 600,
        ignore_whitespace = true,
        virt_text_pos = 'eol',
      },
      -- }}}3

      -- Keymaps & buffer attach {{{3
      on_attach = function(bufnr) -- on_attach {{{4
        local gitsigns = require 'gitsigns'

        local function map(mode, lhs, rhs, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, lhs, rhs, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to next git [c]hange' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Jump to previous git [c]hange' })

        -- Actions (visual)
        map('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk' })
        map('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk' })

        -- Actions (normal)
        map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
        map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
        map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
        map('n', '<leader>hu', gitsigns.undo_stage_hunk or gitsigns.stage_hunk, { desc = 'git [u]ndo stage hunk' })
        map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
        map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
        map('n', '<leader>hb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line' })
        map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
        map('n', '<leader>hD', function() gitsigns.diffthis('@') end, { desc = 'git [D]iff against last commit' })

        -- Toggles
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
        map('n', '<leader>tD', gitsigns.preview_hunk_inline, { desc = '[T]oggle git show [D]eleted' })
      end, -- }}}4
      -- }}}3
    }, -- }}}2
  }, -- }}}1
}
