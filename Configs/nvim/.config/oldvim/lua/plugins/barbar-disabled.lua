vim.opt.termguicolors = true
local map = vim.keymap.set
return {
  {
    "romgrk/barbar.nvim",
    lazy = false,
    enabled = false,
    cmd = { "BarbarEnable", "BarbarDisable" },
    dependencies = {
      "lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
      "nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    -- -- Move to previous/next
    -- custom_keys = {
    --   ["<A-,>"] = {
    --     "<Cmd>BufferPrevious<CR>",
    --     desc = "Previous Buffer",
    --   },
    --   ["<A-.>"] = {
    --     "<Cmd>BufferNext<CR>",
    --     desc = "Next Buffer",
    --   },
    --   -- Re-order to previous/next
    --   ["<A-<>"] = {
    --     "<Cmd>BufferMovePrevious<CR>",
    --     desc = "Move Previous Buffer",
    --   },
    --   ["<A->>"] = { "<Cmd>BufferMoveNext<CR>", desc = "Move Next Buffer" },
    --   -- Goto buffer in position...
    --   ["<A-1>"] = { "<Cmd>BufferGoto 1<CR>", desc = "Goto Buffer 1" },
    --   ["<A-2>"] = { "<Cmd>BufferGoto 2<CR>", desc = "Goto Buffer 2" },
    --   ["<A-3>"] = { "<Cmd>BufferGoto 3<CR>", desc = "Goto Buffer 3" },
    --   ["<A-4>"] = { "<Cmd>BufferGoto 4<CR>", desc = "Goto Buffer 4" },
    --   ["<A-5>"] = { "<Cmd>BufferGoto 5<CR>", desc = "Goto Buffer 5" },
    --   ["<A-6>"] = { "<Cmd>BufferGoto 6<CR>", desc = "Goto Buffer 6" },
    --   ["<A-7>"] = { "<Cmd>BufferGoto 7<CR>", desc = "Goto Buffer 7" },
    --   ["<A-8>"] = { "<Cmd>BufferGoto 8<CR>", desc = "Goto Buffer 8" },
    --   ["<A-9>"] = { "<Cmd>BufferGoto 9<CR>", desc = "Goto Buffer 9" },
    --   ["<A-0>"] = { "<Cmd>BufferLast<CR>", desc = "List Buffers" },
    --
    --   -- Pin/unpin buffer
    --   ["<A-p>"] = {
    --     "<Cmd>BufferPin<CR>",
    --     desc = "Pin Buffer",
    --   },
    --
    --   -- Goto pinned/unpinned buffer
    --   -- :BufferGotoPinned
    --   -- :BufferGotoUnpinned
    --
    --   -- Close buffer
    --   ["<A-c>"] = {
    --     "<Cmd>BufferClose<CR>",
    --     desc = "Close buffer",
    --   },
    --
    --   -- Magic buffer-picking mode
    --   ["<C-p>"] = { "<Cmd>BufferPick<CR>", desc = "Choose buffer" },
    --   ["<C-s-p>"] = {
    --     "<Cmd>BufferPickDelete<CR>",
    --     desc = "Choose buffer to delete",
    --   },
    --
    --   -- Sort automatically by...
    --   ["<Space>bb"] = { "<Cmd>BufferOrderByBufferNumber<CR>", desc = "Order buffers by number" },
    --   ["<Space>bn"] = { "<Cmd>BufferOrderByName<CR>", desc = "Order buffers by name" },
    --   ["<Space>bd"] = { "<Cmd>BufferOrderByDirectory<CR>", desc = "Order buffers by directory" },
    --   ["<Space>bl"] = { "<Cmd>BufferOrderByLanguage<CR>", desc = "Order buffers by language" },
    --   ["<Space>bw"] = { "<Cmd>BufferOrderByWindowNumber<CR>", desc = "Order buffers by window" },
    --   -- Wipeout buffer
    --   --                 :BufferWipeout
    --   -- Close commands
    --   --                 :BufferCloseAllButCurrent
    --   --                 :BufferCloseAllButPinned
    --   --                 :BufferCloseAllButCurrentOrPinned
    --   --                 :BufferCloseBuffersLeft
    --   --                 :BufferCloseBuffersRight
    -- },
  },
}
