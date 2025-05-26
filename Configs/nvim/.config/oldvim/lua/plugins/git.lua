-- Git plugins
-- Lazygit TUI (a user interface for git)
-- with remote-nvim (Adds support for remote development and devcontainers to Neovim)
-- and diffview (simple diff viewer for git)
-- See:
-- https://github.com/jesseduffield/lazygit
-- https://github.com/amitds1997/remote-nvim.nvim
-- https://github.com/sindrets/diffview.nvim
-- lazygit binary is installed with asdf (not in mason registry)
vim.g.lazygit_floating_window_use_plenary = 0
return {
  -- Git Remote support
  {
    "amitds1997/remote-nvim.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = true,
  },
  -- Git TUI
  {
    "kdheepak/lazygit.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
      "amitds1997/remote-nvim.nvim",
    },
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    keys = {
        { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
    },
    config = function()
        require('telescope').load_extension('lazygit')
    end,
  },
  -- Git diff tool
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
  },
  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
      return require "configs.gitsigns"
    end,
  },
}
