-- This is the eonfiguration for nvim-origami - a plugin that enhances folding.
-- https://github.com/chrisgrieser/nvim-origami
return {
  enabled = true,
  'chrisgrieser/nvim-origami',
  event = 'VeryLazy',
  opts = {
    useLspFoldsWithTreesitterFallback = false,
    foldtext = { enabled = false },
    autofold = { enabled = false },
    foldKeymaps = {
      setup = true, -- modifies `h` and `l`
      hOnlyOpensOnFirstColumn = false,
    },
  },
}
