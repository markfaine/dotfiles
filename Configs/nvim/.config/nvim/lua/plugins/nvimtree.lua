--[[
nvim-tree: fast, predictable file explorer {{{1
- Load only on demand (cmd/keys), and skip in headless/Firenvim.
- Clamp float size; compute with vim.o for tiny overhead.
- Debounce watchers; hide heavy dirs; keep visuals sane.
--]]

local HEIGHT_RATIO = 0.8
local WIDTH_RATIO = 0.5

-- Small helper to clamp numbers without pulling in math libs elsewhere
local function clamp(v, min, max) return math.max(min, math.min(max, v)) end

return {
  {
    "nvim-tree/nvim-tree.lua",

    -- On-demand usage; doesn't load at startup.
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    keys = {
      { "<leader>n", "<cmd>NvimTreeToggle<CR>", mode = "n", desc = "Toggle tree Window" },
    },

    -- Skip in non-UI sessions (CI, headless, Firenvim) to avoid any setup work.
    cond = function()
      if vim.g.started_by_firenvim then return false end
      return #vim.api.nvim_list_uis() > 0
    end,

    opts = {
      -- Behavior {{{2
      disable_netrw = true,          -- keep nvim-tree independent of netrw
      hijack_cursor = true,           -- cursor follows file under cursor
      respect_buf_cwd = true,         -- follow buffer cwd where possible
      sync_root_with_cwd = true,      -- keep tree root synced with :pwd
      hijack_unnamed_buffer_when_opening = false, -- avoid surprising hijacks
      -- }}}2

      -- Updates/refresh & performance {{{2
      update_focused_file = {
        enable = true,
        update_root = false,          -- avoid aggressive root switches
      },
      filesystem_watchers = {         -- reduce wakeups without disabling auto-refresh
        enable = true,
        debounce_delay = 100,
      },
      diagnostics = { enable = false }, -- leave off for lower redraw cost
      git = {
        enable = true,
        ignore = true,                -- respect .gitignore (fewer nodes)
        timeout = 400,                -- avoid blocking on slow repos
      },
      filters = {
        dotfiles = false,
        -- Hide heavy/common junk dirs to keep the tree lean. Adjust to taste.
        custom = { "^%.cache$", "^node_modules$", "^dist$", "^build$", "^venv$", "^%.venv$" },
      },
      -- }}}2

      -- View / layout {{{2
      view = {
        relativenumber = true,
        preserve_window_proportions = true,
        float = {
          enable = true,
          open_win_config = function()
            -- Use vim.o to avoid the overhead of option objects
            local screen_w = vim.o.columns
            local screen_h = vim.o.lines - vim.o.cmdheight
            local win_w = math.floor(screen_w * WIDTH_RATIO)
            local win_h = math.floor(screen_h * HEIGHT_RATIO)
            -- Reasonable minimums so the UI never gets too tiny
            win_w = clamp(win_w, 30, screen_w - 4)
            win_h = clamp(win_h, 10, screen_h - 4)
            local center_x = math.floor((screen_w - win_w) / 2)
            local center_y = math.floor((screen_h - win_h) / 2)
            return {
              border = "rounded",
              relative = "editor",
              row = center_y,
              col = center_x,
              width = win_w,
              height = win_h,
            }
          end,
        },
        width = function()
          local w = math.floor(vim.o.columns * WIDTH_RATIO)
          return clamp(w, 30, vim.o.columns - 4)
        end,
      },
      -- }}}2

      -- Rendering {{{2
      renderer = {
        root_folder_label = false,
        group_empty = true,           -- flatten empty directories (fewer nodes)
        highlight_git = true,         -- keep your current look; set false for a tiny speedup
        indent_markers = { enable = true },
        icons = {
          -- Tip: To cut a bit more overhead, set icons.show.git = false
          glyphs = {
            default = "󰈚",
            folder = {
              default = "",
              empty = "",
              empty_open = "",
              open = "",
              symlink = "",
            },
            git = { unmerged = "" },
          },
        },
      },
      -- }}}2

      -- Actions (UX — keep minimal for perf) {{{2
      actions = {
        open_file = {
          -- Closing the tree after opening reduces redraws and keeps layout tidy.
          -- Set to false if you prefer the tree to stay open.
          quit_on_open = true,
          resize_window = true,
        },
      },
      -- }}}2
    },
  },
}
