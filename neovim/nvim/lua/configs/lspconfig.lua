require("mason").setup()
local map = vim.keymap.set
local nomap = vim.keymap.del
local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"
nvlsp.defaults()

----- Keymapping - This on_attach callback is used to override keymaps for LSP
local on_attach = function(client, bufnr)
  nvlsp.on_attach(client, bufnr)

  -- -- Disable keys that aren't used -----------------------------------------
  nomap("n", "K", { buffer = bufnr })
  nomap("n", "<leader>wa", { buffer = bufnr })
  nomap("n", "<leader>wr", { buffer = bufnr })
  nomap("n", "<leader>wl", { buffer = bufnr })
  nomap("n", "<leader>D", { buffer = bufnr })
  map("n", "<leader>l", "<Nop>", { desc = "LSP" })

  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end
  if vim.fn.maparg("K", "n", false, false) == "" then
    map("n", "<leader>lK", "vim.lsp.buf.hover", opts "hover")
  end
  map("n", "<leader>ll", vim.diagnostic.setloclist, opts "diagnostic loclist")
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

local servers = require("mason-lspconfig").get_installed_servers()
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

--- Customize lua_ls to use my keymappings and add vim global to diagnostics
lspconfig["lua_ls"].setup {
  on_attach = on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
    },
  },
}

--- Customize ansiblels to use my keymappings
--- Set the filetype, command, and options
lspconfig.ansiblels.setup {
  on_attach = on_attach,
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
