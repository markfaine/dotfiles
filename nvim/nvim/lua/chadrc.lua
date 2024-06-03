-- This file  needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local utils = require "nvchad.stl.utils"
local M = {}
M.ui = {theme = "catppuccin"}
M.cwd = function()
  local name = vim.loop.cwd()
  name = "%#St_cwd# 󰉖 " .. (name:match "([^/\\]+)[/\\]*$" or name) .. " "
  return (vim.o.columns > 85 and name) or ""
end
M.ui.statusline = {
    theme = "vscode_colored", -- default/vscode/vscode_colored/minimal
    -- default/round/block/arrow separators work only for default statusline theme
    -- round and block will work for minimal theme only
    separator_style = "round",
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cursor", "cwd" }, 
    modules = nil,
  }
return M
