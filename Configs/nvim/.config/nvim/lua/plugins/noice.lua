--[[
Noice: require nolazyredraw {{{1
Noice needs 'lazyredraw' disabled to render UI elements correctly.
We enforce it at startup and re-assert during cmdline usage.
--]]

return {
  "folke/noice.nvim",
  event = "VeryLazy",

  -- Ensure nolazyredraw before Noice or its views are used
  init = function()
    if vim.opt.lazyredraw:get() then vim.opt.lazyredraw = false end
    -- Re-assert in case another plugin flips it later
    vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineChanged" }, {
      group = vim.api.nvim_create_augroup("NoiceNolazyredraw", { clear = true }),
      callback = function() if vim.opt.lazyredraw:get() then vim.opt.lazyredraw = false end end,
    })
  end,

  -- Skip setup in non-UI sessions for zero cost
  cond = function()
    local ui = require("core.autocmds")
    return ui.is_ui
  end,

  ---@type fun(): NoiceConfig
  opts = function()
    local use_cmp = false
    return {
      -- Global throttle to reduce re-render churn
      throttle = 1000,

      lsp = {
        progress = { enabled = false }, -- disable spinner
        -- Don’t auto-pop signature; request it when needed
        signature = { auto_open = { enabled = false } },
        -- Keep TS markdown rendering for better docs
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = use_cmp,
        },
      },

      -- Trim common noise and route long messages
      routes = {
        -- Skip “written” and file stats
        { filter = { event = "msg_show", find = "written" }, opts = { skip = true } },
        { filter = { event = "msg_show", kind = "", find = "%d+L, %d+B" }, opts = { skip = true } },
        -- Skip incremental search count spam
        { filter = { event = "msg_show", kind = "search_count" }, opts = { skip = true } },
      },

      -- Views: add borders and clamp sizes for LSP docs
      views = {
        hover = {
          border = { style = "rounded" },
          win_options = { winblend = 0 },
          size = { max_width = 80, max_height = 20 },
        },
        signature = {
          border = { style = "rounded" },
          win_options = { winblend = 0 },
          size = { max_width = 80, max_height = 20 },
        },
      },

      -- Presets: keep your layout, add LSP doc borders
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true, -- was false; border helps readability
      },
    }
  end,

  dependencies = {
    -- Required UI library
    "MunifTanjim/nui.nvim",
    -- Use notify view for clean, async notifications (optional but recommended)
    "rcarriga/nvim-notify",
  },
}
