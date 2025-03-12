--
require("nvchad.configs.lspconfig").defaults()
local map = vim.keymap.set
local nomap = vim.keymap.del
-- local nomap = vim.keymap.del
local servers = { "html", "cssls", "pyright", "bashls", "jinja_lsp" }
local nvlsp = require "nvchad.configs.lspconfig"
local lspconfig = require "lspconfig"

local M = {}
M.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end
  -- map("n", "<leader>lK", vim.lsp.buf.hover, opts "Hover")
  map("n", "<leader>ll", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })
  map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, opts "Code action")
  map("n", "lD", vim.lsp.buf.declaration, opts "Go to declaration")
  map("n", "ld", vim.lsp.buf.definition, opts "Go to definition")
  map("n", "li", vim.lsp.buf.implementation, opts "Go to implementation")
  map("n", "<leader>lh", vim.lsp.buf.signature_help, opts "Show signature help")
  map("n", "<leader>la", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  map("n", "<leader>lr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")
  map("n", "<leader>lL", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "List workspace folders")
  map("n", "<leader>lT", vim.lsp.buf.type_definition, opts "Go to type definition")
  map("n", ",r", require "nvchad.lsp.renamer", opts "refactor name")
  map({ "n", "v" }, "<leader>lc", vim.lsp.buf.code_action, opts "Code action")
  map("n", "lgR", vim.lsp.buf.references, opts "Show references")
end

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = M.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- ansiblels - didn't work in the loop above

require("lspconfig").ansiblels.setup {
  on_attach = M.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  settings = {
    ansible = {
      cmd = { "ansible-language-server", "--stdio" },
      filetypes = { "yaml.ansible" },
      validation = {
        enabled = true,
        lint = {
          enabled = true,
          arguments = { "--fix=none" },
          path = "ansible-lint",
        },
      },
    },
  },
}
