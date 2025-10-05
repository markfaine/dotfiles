local M = {}

-- Opportunistic setup: ufo > pretty-fold > origami; fallback stays active
function M.setup()
  -- nvim-ufo (rich virtual text folds)
  local ok_ufo, ufo = pcall(require, 'ufo')
  if ok_ufo then
    ufo.setup({
      provider_selector = function(_, _, _) return { 'treesitter', 'indent' } end,
      -- keep default virt text handler or customize as needed
    })
    -- convenience maps
    vim.keymap.set('n', 'zR', ufo.openAllFolds, { desc = 'Open all folds' })
    vim.keymap.set('n', 'zM', ufo.closeAllFolds, { desc = 'Close all folds' })
    return
  end

  -- pretty-fold.nvim (enhanced foldtext)
  local ok_pf, pf = pcall(require, 'pretty-fold')
  if ok_pf then
    pf.setup({
      keep_indentation = false,
      fill_char = ' ',
      sections = {
        left = { 'content' },
        right = { '  •  ', 'number_of_folded_lines', ': ', 'percentage' },
      },
    })
    return
  end

  -- nvim-origami (auto open/close folds; doesn’t change foldtext)
  local ok_org, origami = pcall(require, 'origami')
  if ok_org then
    origami.setup()
    -- fallback foldtext remains in effect
    return
  end

  -- none found: native fallback already active
end

return M