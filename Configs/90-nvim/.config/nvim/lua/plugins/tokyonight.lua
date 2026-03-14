return {
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    opts = {
      style = 'night',           -- night | storm | moon | day
      light_style = 'day',       -- used when background=light
      transparent = false,
      terminal_colors = true,
      styles = {
        comments  = { italic = true },
        sidebars  = 'dark',      -- dark | transparent | normal
        floats    = 'dark',
      },
      dim_inactive = false,
      lualine_bold = true,

      on_colors = function(colors)
        colors.comment = '#5e7b8c'
      end,

      on_highlights = function(hl, c)
        local border = c.border or c.blue -- fallback for older palette keys
        local none = 'NONE'

        -- Generic UI (works across Telescope, Snacks, etc.)
        hl.NormalFloat = { fg = hl.Normal.fg, bg = c.bg_float }
        hl.FloatBorder = { fg = border,       bg = c.bg_float }
        hl.WinSeparator = { fg = border,      bg = none }
        hl.Pmenu        = { bg = c.bg_popup }
        hl.PmenuSel     = { bg = c.bg_highlight }
        hl.PmenuThumb   = { bg = c.fg_gutter }

        -- Diagnostics virtual text without boxed backgrounds
        hl.DiagnosticVirtualTextError = { fg = c.error,   bg = none }
        hl.DiagnosticVirtualTextWarn  = { fg = c.warning, bg = none }
        hl.DiagnosticVirtualTextInfo  = { fg = c.info,    bg = none }
        hl.DiagnosticVirtualTextHint  = { fg = c.hint,    bg = none }
      end,
    },
    config = function(_, opts)
      vim.opt.termguicolors = true
      require('tokyonight').setup(opts)
      local function apply(style)
        local target = style and ('tokyonight-' .. style) or 'tokyonight'
        pcall(vim.cmd.colorscheme, target)
      end
      apply(opts.style or 'night')

      -- Commands: cycle variants / toggle transparency
      local variants = { 'night', 'storm', 'moon', 'day' }
      vim.api.nvim_create_user_command('TokyoNightCycle', function()
        local current = vim.g.colors_name or ''
        local idx = 1
        for i, v in ipairs(variants) do
          if current == 'tokyonight-' .. v then idx = i break end
        end
        local nextv = variants[(idx % #variants) + 1]
        opts.style = nextv
        require('tokyonight').setup(opts)
        apply(nextv)
      end, { desc = 'Cycle TokyoNight variant' })

      vim.api.nvim_create_user_command('TokyoNightTransparent', function()
        opts.transparent = not opts.transparent
        require('tokyonight').setup(opts)
        apply(opts.style or 'night')
        vim.notify('TokyoNight transparency: ' .. (opts.transparent and 'ON' or 'OFF'), vim.log.levels.INFO)
      end, { desc = 'Toggle TokyoNight transparency' })

      -- Follow background option (auto switch day/night)
      vim.api.nvim_create_autocmd('OptionSet', {
        pattern = 'background',
        callback = function()
          local bg = vim.o.background
          local target = (bg == 'light') and 'day' or (opts.style ~= 'day' and opts.style or 'night')
          opts.style = target
          require('tokyonight').setup(opts)
          apply(target)
        end,
        desc = 'Auto-switch TokyoNight variant when background changes',
      })
    end,
  },
}
