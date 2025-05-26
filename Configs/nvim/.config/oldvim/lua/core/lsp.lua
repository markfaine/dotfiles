--- for mapping keymaps
local map = vim.keymap.set

-- Allow virtual lines
vim.diagnostic.config {
  virtual_lines = { current_line = true },
  virtual_text = false,
  underline = false,
  update_in_insert = false,
}

-- Reserve a space in the gutter
-- This will avoid an annoying layout shift in the screen
vim.opt.signcolumn = "yes"

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP actions",
  callback = function(event)
    local function opts(desc)
      return { buffer = event.buf, desc = "LSP " .. desc }
    end
    map("n", "<leader>l", "<Nop>", { desc = "LSP" })
    if vim.fn.maparg("K", "n", false, false) == "" then
      map("n", "<leader>lK", "vim.lsp.buf.hover", opts "hover")
    end
    map("n", "<leader>ll", vim.diagnostic.setloclist, opts "diagnostic loclist")
    map({ "n" }, "<leader>la", vim.lsp.buf.code_action, opts "Code action")
    map({ "v" }, "<C-la>", vim.lsp.buf.code_action, opts "Code action")
    map("n", "<leader>lD", vim.lsp.buf.declaration, opts "Go to declaration")
    map("n", "<leader>ld", vim.lsp.buf.definition, opts "Go to definition")
    map("n", "<leader>li", vim.lsp.buf.implementation, opts "Go to implementation")
    map("n", "<leader>lh", vim.lsp.buf.signature_help, opts "Show signature help")
    map("n", "<leader>la", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
    map("n", "<leader>lr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")
    map("n", "<leader>lL", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts "List workspace folders")
    map({ "n" }, "<leader>lf", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts "Format")
    map({ "x" }, "<C-lf>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts "Format")
    map("n", "<leader>lT", vim.lsp.buf.type_definition, opts "Go to type definition")
    map("n", "<leader>lr", require "nvchad.lsp.renamer", opts "refactor name")
    map({ "n" }, "<leader>lc", vim.lsp.buf.code_action, opts "Code action")
    map({ "v" }, "<C-lc>", vim.lsp.buf.code_action, opts "Code action")
    map("n", "<leader>lR", vim.lsp.buf.references, opts "Show references")
  end,
})

-- Auto format on save if attached to lsp
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP actions",
  callback = function(event)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = buffer,
      callback = function()
        vim.lsp.buf.format { async = false }
      end,
    })
  end,
})

local capabilities = {
  textDocument = {
    foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    },
  },
}

-- Setup language servers.
vim.lsp.config("*", {
  capabilities = capabilities,
  root_markers = { ".git" },
})

--- Customize lua_ls to use my keymappings and add vim global to diagnostics
--vim.lsp.config["luals"].setup {
-- --on_attach = M.on_attach,
-- --on_init = M.on_init,
-- --capabilities = M.capabilities,
-- settings = {
--   Lua = {
--     diagnostics = { globals = { "vim" } },
--   },
-- },
--}

--- Customize ansiblels to use my keymappings
--- Set the filetype, command, and options
--vim.lsp.config.ansiblels.setup {
-- on_attach = M.on_attach,
-- on_init = M.on_init,
-- capabilities = M.capabilities,
-- settings = {
--   ansible = {
--     cmd = { "ansible-language-server", "--stdio" },
--     filetypes = { "yaml.ansible" },
--     validation = {
--       enabled = true,
--       lint = {
--         enabled = true,
--         arguments = { "--fix=none" },
--         path = "ansible-lint",
--       },
--     },
--   },
-- },
--}

vim.lsp.enable {
  "ansiblels",
  --"bashls",
  --"yamlls",
  "pylsp",
  --"gitlab_cs_ls",
  "luals",
}
