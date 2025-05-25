-- keymaps
local map = vim.keymap.set

return {
  "joshuadanpeterson/typewriter",
  lazy = true,
  enabled = false,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    enable_notifications = false,
    keep_cursor_position = true,
    enable_horizontal_scroll = false,
  },
  config = function(plugin, opts)
    -- autocommand for entering typewriter mode
    require("typewriter").setup(opts)
    local commands = require "typewriter.commands"
    vim.api.nvim_create_autocmd("FileType", {
      desc = "Enable typewriter mode",
      pattern = "php,go,rst,javascript,python,html,css,bash,sh,sql,yaml,json,c,cpp,java,lua,markdown,make,perl",
      callback = function()
        vim.api.nvim_create_autocmd("BufEnter", {
          pattern = "<buffer>",
          callback = function()
            -- require("typewriter.commands").enable_typewriter_mode()
            -- setup key mappings
            -- Toggle typewriter mode
            map("n", "<leader>Tt", function()
              commands.toggle_typewriter_mode()
            end, { noremap = true, silent = true, desc = "Typewriter: toggle" })

            -- Center the current code block and cursor
            map("n", "<leader>Tc", function()
              commands.center_cursor()
            end, { noremap = true, silent = true, desc = "Typewriter: center cursor" })

            -- Move the top of the current code block to the top of the screen
            map("n", "<leader>TT", function()
              commands.move_to_top_of_block()
            end, { noremap = true, silent = true, desc = "Typewriter: move to top" })

            -- Move the bottom of the current code block to the bottom of the screen
            map("n", "<leader>Tb", function()
              commands.move_to_bottom_of_block()
            end, { noremap = true, silent = true, desc = "Typewriter: move to bottom" })
          end,
        })
      end,
    })
  end,
}
