-- This plugin adds the yaml.ansible (filetype) among other things.
-- See: https://github.com/mfussenegger/nvim-ansible for more info
return {
  {
    "mfussenegger/nvim-ansible",
    ft = "yaml.ansible",
    -- Set keymaps specifically for Ansible files
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        desc = "Ansible Mappings",
        pattern = "yaml.ansible",
        callback = function()
          vim.keymap.set("n", "<leader>ar", function()
            require("ansible").run()
          end, { noremap = true, silent = true, desc = "Run Playbook" })
          vim.keymap.set(
            "v",
            "<C-ar>",
            ":w<CR> :lua require('ansible').run()<CR>",
            { noremap = true, silent = true, desc = "Run Playbook" }
          )
        end,
      })
    end,
  },
}
