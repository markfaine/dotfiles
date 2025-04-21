-- Completion plugin
-- See:
-- https://github.com/Saghen/blink.cmp
return {
  "saghen/blink.cmp",
  enabled = false,
  -- optional: provides snippets for the snippet source
  dependencies = { "rafamadriz/friendly-snippets" },
  version = "1.*",
  -- See :h blink-cmp-config-keymap for defining your own keymap
  keymap = { preset = "default" },
  -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
  appearance = {
    nerd_font_variant = "normal",
  },
  -- (Default) Only show the documentation popup when manually triggered
  completion = { documentation = { auto_show = false } },
  -- Default list of enabled providers defined
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
  -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
  -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
  --
  -- See the fuzzy documentation for more information
  fuzzy = { implementation = "prefer_rust_with_warning" },
}
