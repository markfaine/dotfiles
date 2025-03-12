local null_ls = require "null-ls"
null_ls.setup()

require("mason-null-ls").setup {
  ensure_installed = { "stylua", "jq" },
  handlers = {
    function() end, -- disables automatic setup of all null-ls sources
    shfmt = function(source_name, methods)
      -- custom logic
      require("mason-null-ls").default_setup(source_name, methods) -- to maintain default behavior
    end,
  },
}
