-- vim: foldmethod=marker foldlevel=1

--[[ nvim-origami — folding ergonomics {{{1
Lightweight, conflict-free setup: lazy-load by keys, keep native foldtext, no h/l remaps.
Integrates with core/extras/folds.lua per-window fold selection.
}}}1 --]]

return {
  'chrisgrieser/nvim-origami',
  enabled = true,

  -- Keys {{{1
  -- Lazy-load on first actual use; avoids loading at startup
  keys = {
    {
      'zL',
      function()
        require('origami').l()
      end,
      desc = 'Origami: open fold at cursor',
    },
    {
      'zH',
      function()
        require('origami').h()
      end,
      desc = 'Origami: close fold at cursor',
    },
  },
  -- }}}1

  -- Options {{{1
  -- Keep Origami focused: no auto-folding, no foldtext override, no h/l remaps
  opts = {
    useLspFoldsWithTreesitterFallback = false, -- let core/extras/folds.lua pick method
    foldtext = { enabled = false }, -- keep custom/native foldtext
    autofold = { enabled = false }, -- no surprise auto-closing
    foldKeymaps = {
      setup = false, -- don’t remap h/l
      hOnlyOpensOnFirstColumn = true,
    },
  },
  -- }}}1

  -- Setup {{{1
  config = function(_, opts)
    require('origami').setup(opts)
  end,
  -- }}}1
}
