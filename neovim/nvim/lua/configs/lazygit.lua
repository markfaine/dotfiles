require("telescope").load_extension "lazygit"
local lazygit = require "lazygit"
lazygit.cmd = {
  "LazyGit",
  "LazyGitConfig",
  "LazyGitCurrentFile",
  "LazyGitFilter",
  "LazyGitFilterCurrentFile",
}
vim.g.lazygit_floating_window_use_plenary = 0
