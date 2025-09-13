-- vim: foldmethod=marker foldlevel=1

--[[ lazydev.nvim — Lua dev helpers {{{1
Performance-oriented setup:
- Loads only for Lua buffers (ft = 'lua')
- Adds 3rd-party type libs, gated by keywords to avoid scanning
- Single source of truth for opts (avoid duplicating in dependencies)
}}}1 --]]

return {
  {
    'folke/lazydev.nvim',
    ft = 'lua', -- only load when editing Lua files

    -- Options {{{1
    opts = {
      -- Add type libraries on demand (keyword-gated to reduce overhead)
      library = {
        -- luv: enable types when using vim.uv APIs
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        -- busted: enable test types when using busted globals
        { path = '${3rd}/busted/library', words = { '^%s*describe%W', '^%s*it%W', '^%s*before_each%W', '^%s*after_each%W' } },
        -- luassert (optional): assertion helpers in tests
        { path = '${3rd}/luassert/library', words = { '%f[%w]assert%f[%W]' } },
      },
    },
    -- }}}1
  },
}
