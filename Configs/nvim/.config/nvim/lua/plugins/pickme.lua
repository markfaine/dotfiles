--[[
PickMe: lightweight “pickers” facade with smart loading {{{1
- Load only on demand (command/keys), not on VeryLazy.
- Avoid initializing in headless/Firenvim sessions.
- Prefer Snacks picker if present; fall back safely.
--]]

return {
  {
    "2KAbhishek/pickme.nvim",

    -- On-demand: the command is enough; avoid eager "VeryLazy" cost.
    cmd = "PickMe",

    -- Skip in non-UI contexts (headless CI, Firenvim) to save cycles.
    cond = function()
      if vim.g.started_by_firenvim then return false end
      return #vim.api.nvim_list_uis() > 0
    end,

    -- Snacks provides a fast picker UI; keep as dependency since it's in your setup.
    dependencies = {
      "folke/snacks.nvim", -- used when picker_provider = "snacks"
    },

    -- Compute provider at runtime:
    -- - use global override: vim.g.pickme_provider = "snacks" | "builtin" (or others supported by pickme)
    -- - default to "snacks" if available, otherwise "builtin" to avoid errors
    ---@type fun(): {picker_provider:string, add_default_keybindings:boolean}
    opts = function()
      local provider = vim.g.pickme_provider
      if not provider then
        local ok = pcall(require, "snacks")
        provider = ok and "snacks" or "builtin" -- adjust fallback if you use another provider
      end
      return {
        picker_provider = provider,
        -- Keep default keymaps for convenience. If you customize via which-key,
        -- set this to false and add your own bindings.
        add_default_keybindings = true,
      }
    end,

    -- Examples (opt-in): map common picks without loading until used
    keys = {
      { "<leader>pf", function() require("pickme").pick("files") end, desc = "Pick Files" },
      { "<leader>pb", function() require("pickme").pick("buffers") end, desc = "Pick Buffers" },
      { "<leader>ps", function() require("pickme").pick("lsp_symbols") end, desc = "Pick LSP Symbols" },
    },
  },
}
