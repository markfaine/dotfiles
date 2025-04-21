return {
  {
    "nvchad/ui",
    lazy = false,
    config = function()
      require "nvchad"
    end,
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-tree/nvim-web-devicons" },
      {
        "nvchad/base46",
        build = function()
          require("base46").load_all_highlights()
        end,
      },
      { "nvchad/volt" },
    },
  },
}
