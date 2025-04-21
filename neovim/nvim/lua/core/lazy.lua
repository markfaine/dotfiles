local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
    defaults = { lazy = true, },
    spec = {
        {import = "plugins"},
    },
    change_detection = {
        notify = false,
        enabled = true,
    },
    install = { colorscheme = { "catppuccin" } },
    performance = {
        cache = {enabled = true},
        performance = {
	  rtp = {
            disabled_plugins = {
              "2html_plugin",
              "tohtml",
              "getscript",
              "getscriptPlugin",
              "gzip",
              "logipat",
              "netrw",
              "netrwPlugin",
              "netrwSettings",
              "netrwFileHandlers",
              "matchit",
              "tar",
              "tarPlugin",
              "rrhelper",
              "spellfile_plugin",
              "vimball",
              "vimballPlugin",
              "zip",
              "zipPlugin",
              "tutor",
              "rplugin",
              "syntax",
              "synmenu",
              "optwin",
              "compiler",
              "bugreport",
              "ftplugin",
            },
          },
        },
    },
    ui = {
        border = "single",
        size = {
            width = 0.7,
            height = 0.7,
        },
	icons = {
          ft = "",
          lazy = "󰂠 ",
          loaded = "",
          not_loaded = "",
        },
    },
})
