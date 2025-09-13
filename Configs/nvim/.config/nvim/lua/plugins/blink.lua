-- vim: foldmethod=marker foldlevel=1

--[[ blink.cmp — fast autocompletion {{{1
Performance-oriented setup:
- Lazy-loads on first InsertEnter (cuts startup work)
- Lua dev helpers load only for Lua buffers
- Copilot kind injection made idempotent
}}}1 --]]

return {
  -- Autocompletion core {{{1
  'saghen/blink.cmp',
  event = 'InsertEnter',  -- load on first actual completion need
  version = '1.*',
  dependencies = {
    -- Copilot completion source (loads alongside blink)
    'giuxtaposition/blink-cmp-copilot',

    -- Snippet engine
    {
      'L3MON4D3/LuaSnip',
      version = '2.*',
      build = (function()
        if vim.fn.has('win32') == 1 or vim.fn.executable('make') == 0 then
          return
        end
        return 'make install_jsregexp'
      end)(),
      dependencies = {
        {
          'rafamadriz/friendly-snippets',
          config = function()
            require('luasnip.loaders.from_vscode').lazy_load()
          end,
        },
      },
      opts = {},
    },

    -- Lua dev completion hints (load only for Lua) {{{2
    { 'folke/lazydev.nvim', ft = 'lua', opts = {} },
    -- }}}2
  },
  --- @module 'blink.cmp'
  --- @type blink.cmp.Config
  opts = {
    -- Appearance {{{1
    appearance = {
      nerd_font_variant = 'mono',
      kind_icons = {
        Copilot = '',
        Text = '󰉿',
        Method = '󰊕',
        Function = '󰊕',
        Constructor = '󰒓',
        Field = '󰜢',
        Variable = '󰆦',
        Property = '󰖷',
        Class = '󱡠',
        Interface = '󱡠',
        Struct = '󱡠',
        Module = '󰅩',
        Unit = '󰪚',
        Value = '󰦨',
        Enum = '󰦨',
        EnumMember = '󰦨',
        Keyword = '󰻾',
        Constant = '󰏿',
        Snippet = '󱄽',
        Color = '󰏘',
        File = '󰈔',
        Reference = '󰬲',
        Folder = '󰉋',
        Event = '󱐋',
        Operator = '󰪚',
        TypeParameter = '󰬛',
      },
    },
    -- }}}1

    -- Completion UX {{{1
    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },
    -- }}}1

    -- Sources {{{1
    sources = {
      default = { 'lsp', 'path', 'buffer', 'snippets', 'copilot' },
      providers = {
        -- Make Copilot kind injection idempotent
        copilot = {
          name = 'copilot',
          module = 'blink-cmp-copilot',
          score_offset = 100,
          async = true,
          transform_items = function(_, items)
            local types = require('blink.cmp.types')
            local kinds = types.CompletionItemKind
            local copilot_idx
            for i, k in ipairs(kinds) do
              if k == 'Copilot' then copilot_idx = i break end
            end
            if not copilot_idx then
              table.insert(kinds, 'Copilot')
              copilot_idx = #kinds
            end
            for _, item in ipairs(items) do
              item.kind = copilot_idx
            end
            return items
          end,
        },
      },
    },
    -- }}}1

    -- Engine {{{1
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    signature = { enabled = true },
    -- }}}1
  },
  opts_extend = { 'sources.default' },
  -- }}}1
}
