--- Generate docstrings
--- See: https://github.com/kkoomen/vim-doge
--- Requires binary vim-doge-helper
local map = vim.keymap.set
--- The type of docstring to use
vim.g.doge_doc_standard_python = "numpy"
--- See mappings in mappings.lua
vim.g.doge_enable_mappings = 0
return {
  {
    "kkoomen/vim-doge",
     ft = "python",
     keys = {
	{"<leader>dg", "<Plug>(doge-generate)<esc><CR>",  desc = "Generate docstring" },
	{"<leader>df", "<Plug>(doge-comment-jump-forward)",  desc = "Next docstring" },
	{"<leader>db", "<Plug>(doge-comment-jump-backward)",  desc = "Previous docstring" },
      },
  },
}
