--[[
Snacks: fast UI micro-modules with sensible gating {{{1
- Keep bigfile/quickfile eager to protect performance.
- Disable UI-heavy modules in headless, tiny, or file-arg sessions.
- Keep behavior predictable; no invasive defaults.
--]]

---@type LazySpec
return {
  "folke/snacks.nvim",

  -- Eager load is intentional so bigfile/quickfile can act before heavy plugins.
  -- This preserves your current behavior and protects large-file performance.
  lazy = false,
  priority = 1000,

  -- Build opts dynamically to avoid work in headless or constrained UIs.
  ---@type snacks.Config|fun():snacks.Config
  opts = function()
    local headless = #vim.api.nvim_list_uis() == 0
    local has_args = vim.fn.argc(-1) > 0
    -- Basic heuristic: only show dashboard in roomy, interactive UIs with no file args
    local roomy_ui = not headless and vim.o.lines >= 19 and vim.o.columns >= 60
    local ui_ok = not headless

    return {
      -- Keep these on: they short-circuit heavy features on large/single-file cases.
      bigfile = { enabled = true },      -- auto-disables slow features on large files
      quickfile = { enabled = true },    -- speed up opening a single file

      -- UI/visual modules: gated to avoid headless overhead.
      dashboard = { enabled = roomy_ui and not has_args },
      explorer = { enabled = false },    -- stick with your preferred file explorer
      indent = { enabled = ui_ok },      -- guides; harmless but skip in headless
      input = { enabled = ui_ok },       -- nicer prompts
      picker = { enabled = ui_ok },      -- fuzzy pickers; load when used
      notifier = { enabled = false },    -- let Noice/nvim-notify handle notifications
      scope = { enabled = ui_ok },       -- visually scope current context
      scroll = { enabled = ui_ok },      -- smooth scrolling
      toggle = { enabled = true },       -- tiny helpers; negligible cost
      statuscolumn = {
        enabled = true,
        -- if dup signs appear, disable git segment here:
        git = { enabled = false },
      }, -- avoid churn in headless/tiny UIs
      words = { enabled = ui_ok },       -- subtle word highlights
    }
  end,

  ---@param buf number
  is_large = function(buf)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
    return ok and stats and stats.size and stats.size > (vim.g.large_file_threshold_bytes or 200*1024)
  end
}
