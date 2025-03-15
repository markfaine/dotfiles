local null_ls = require "null-ls"
null_ls.setup()

require("mason-null-ls").setup {
  handlers = {
    function() end, -- disables automatic setup of all null-ls sources
    methods = { diagnostics = true }, -- only diagnostic methods
    yamllint = function(source_name, methods)
      require("mason-null-ls").default_setup(source_name, methods)
    end,
    rstcheck = function(source_name, methods)
      require("mason-null-ls").default_setup(source_name, methods)
    end,
    sphinx_lint = function(source_name, methods)
      require("mason-null-ls").default_setup(source_name, methods)
    end,
  },
}
