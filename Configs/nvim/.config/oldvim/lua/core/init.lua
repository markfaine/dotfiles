require("core.base")
require("core.lazy")
require("core.nvchad")
require("core.lsp")
require("core.options")
vim.schedule(function()
  require "core.mappings"
end)
require("core.autocommands")
