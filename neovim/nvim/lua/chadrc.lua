-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
require('nvchad.chadrc')
local M = {}

-- https://github.com/NvChad/ui/blob/8fc9f2502bf580f9a9b83f77f7a2e0b8f6f24191/lua/nvconfig.lua#L3
M.base64 = {
  theme = "catppuccin",
}

-- https://github.com/NvChad/ui/blob/8fc9f2502bf580f9a9b83f77f7a2e0b8f6f24191/lua/nvconfig.lua#L13
M.ui = {
  telescope = { style = "borderless" },
}

-- https://github.com/NvChad/ui/blob/8fc9f2502bf580f9a9b83f77f7a2e0b8f6f24191/lua/nvconfig.lua#L26
M.ui.statusline = {
    theme = "vscode_colored", -- default/vscode/vscode_colored/minimal
    separator_style = "round",
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cursor", "cwd" },
    modules = nil,
}

-- https://github.com/NvChad/ui/blob/8fc9f2502bf580f9a9b83f77f7a2e0b8f6f24191/lua/nvconfig.lua#L46
M.ui.nvdash = {
  load_on_startup = true,
  header = {
    "  MMMMMMMM               MMMMMMMMFFFFFFFFFFFFFFFFFFFFFF  ",
    "  M:::::::M             M:::::::MF::::::::::::::::::::F  ",
    "  M::::::::M           M::::::::MF::::::::::::::::::::F  ",
    "  M:::::::::M         M:::::::::MFF::::::FFFFFFFFF::::F  ",
    "  M::::::::::M       M::::::::::M  F:::::F       FFFFFF  ",
    "  M:::::::::::M     M:::::::::::M  F:::::F               ",
    "  M:::::::M::::M   M::::M:::::::M  F::::::FFFFFFFFFF     ",
    "  M::::::M M::::M M::::M M::::::M  F:::::::::::::::F     ",
    "  M::::::M  M::::M::::M  M::::::M  F:::::::::::::::F     ",
    "  M::::::M   M:::::::M   M::::::M  F::::::FFFFFFFFFF     ",
    "  M::::::M    M:::::M    M::::::M  F:::::F               ",
    "  M::::::M     MMMMM     M::::::M  F:::::F               ",
    "  M::::::M               M::::::MFF:::::::FF             ",
    "  M::::::M               M::::::MF::::::::FF             ",
    "  M::::::M               M::::::MF::::::::FF             ",
    "  MMMMMMMM               MMMMMMMMFFFFFFFFFFF             ",
    "                                                         ",
  },
}
return M


