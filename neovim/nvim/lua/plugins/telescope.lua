-- Key mappings for telescope
local map = vim.keymap.set
local builtin = require'telescope.builtin'
local actions = require'telescope.actions'
map("n", "<leader>lg", function() builtin.live_grep() end, { desc = "telescope live grep" })
map("n", "<leader>fb", function() builtin.buffers{ on_complete = { function() vim.cmd"stopinsert" end } } end, { desc = "telescope find buffers" })
map("n", "<leader>tH", function() builtin.help_tags() end, { desc = "telescope help tags" })
map("n", "<leader>m", function() builtin.marks() end, { desc = "telescope find marks" })
map("n", "<leader>fo", function() builtin.old_files() end, { desc = "telescope find oldfiles" })
map("n", "<leader>fz", function() builtin.current_buffer_fuzzy_find() end, { desc = "telescope find in current buffer" })
map("n", "<leader>gc", function() builtin.git_commits{ on_complete = { function() vim.cmd"stopinsert" end } } end, { desc = "telescope git commits" })
map("n", "<leader>gs", function() builtin.git_status{ on_complete = { function() vim.cmd"stopinsert" end } } end, { desc = "telescope git status" })
map("n", "<leader>t", function() builtin.terms{ on_complete = { function() vim.cmd"stopinsert" end } } end, { desc = "telescope pick hidden term" })
map("n", "<leader>th", function() require("nvchad.themes").open() end, { desc = "telescope nvchad themes" })
map("n", "<leader>ff", function() builtin.find_files() end, { desc = "telescope find files" })
map("n", "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>", { desc = "telescope find all files" })

return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPost", "BufNewFile" },
        cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
        build = ":TSUpdate",
	config = function()
	  require "configs.treesitter"
	end,
      },
    },
    cmd = "Telescope",
    defaults = {
      prompt_prefix = "   ",
      selection_caret = " ",
      entry_prefix = " ",
      sorting_strategy = "ascending",
      layout_config = {
        horizontal = {
          prompt_position = "top",
          preview_width = 0.55,
        },
        width = 0.87,
        height = 0.80,
      },
      mappings = {
        n = {
	  ["<esc>"] = actions.close,
        },
        i = {
          ["<C-u>"] = false,
        },
      },
    },
    pickers = {
	buffers = {
          mappings = {
            i = {
	     ["<c-d>"] = actions.delete_buffer + actions.move_to_top,
            }
          }
	},
        find_files = {
            find_command=rg,--ignore,--hidden,--files prompt_prefix=🔍
	},
    },
    extensions_list = { "themes", "terms" },
    extensions = {},
    lazy = false,
  },
}
