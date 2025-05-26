local trim_spaces = true
return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    lazy = false,
    config = function()
      function _G.set_terminal_keymaps()
        local function opts(desc)
          return { buffer = 0, desc = "terminal " .. desc }
        end
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts "escape terminal mode")
        vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts "right")
        vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts "down")
        vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts "up")
        vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts "left")
        vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts "close")
        vim.keymap.set("n", "<leader>h", "<Cmd>ToggleTerm direction=horizontal<CR>", opts "horizontal")
        vim.keymap.set("n", "<leader>v", "<Cmd>ToggleTerm direction=vertical<CR>", opts "vertical")
        vim.keymap.set("n", "<C-tab>", "<Cmd>ToggleTerm direction=tab<CR>", opts "tab")
        vim.keymap.set("n", "<C-tab>", "<Cmd>ToggleTermToggleAll<CR>", opts "toggle all")
      end
      vim.keymap.set("v", "<space>s", function()
        require("toggleterm").send_lines_to_terminal("single_line", trim_spaces, { args = vim.v.count })
      end, { desc = "Send lines to terminal" })
      vim.keymap.set("v", "<space>l", function()
        require("toggleterm").send_lines_to_terminal("visual_lines", trim_spaces, { args = vim.v.count })
      end, { desc = "Send lines to terminal" })
      vim.keymap.set("v", "<space>S", function()
        require("toggleterm").send_lines_to_terminal("visual_selection", trim_spaces, { args = vim.v.count })
      end, { desc = "Send selection to terminal" })
      vim.keymap.set("n", [[<leader><c-\>]], function()
        set_opfunc(function(motion_type)
          require("toggleterm").send_lines_to_terminal(motion_type, false, { args = vim.v.count })
        end)
        vim.api.nvim_feedkeys("g@", "n", false)
      end, { desc = "Send motion to terminal" })
      vim.keymap.set("n", [[<leader><c-\><c-\>]], function()
        set_opfunc(function(motion_type)
          require("toggleterm").send_lines_to_terminal(motion_type, false, { args = vim.v.count })
        end)
        vim.api.nvim_feedkeys("g@_", "n", false)
      end, { desc = "Send line to terminal" })
      vim.keymap.set("n", [[<leader><leader><c-\>]], function()
        set_opfunc(function(motion_type)
          require("toggleterm").send_lines_to_terminal(motion_type, false, { args = vim.v.count })
        end)
        vim.api.nvim_feedkeys("ggg@G''", "n", false)
      end, { desc = "Send whole file to terminal" })
      vim.cmd "autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()"
    end,
  },
}
