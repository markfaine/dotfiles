local util = require "lspconfig.util"

local root_files = {
  ".luarc.json",
  ".luarc.jsonc",
  ".luacheckrc",
  ".stylua.toml",
  "stylua.toml",
  "selene.toml",
  "selene.yml",
  ".git",
}

return {
  default_config = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = util.root_pattern(root_files),
    single_file_support = true,
    log_level = vim.lsp.protocol.MessageType.Warning,
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
      },
    },
  },
}
