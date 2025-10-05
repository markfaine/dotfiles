-- vim: foldmethod=marker foldlevel=1

--[[ copilot.lua — GitHub Copilot core {{{1
Performance-oriented setup:
- Lazy-load on first InsertEnter (and via :Copilot cmd)
- Inline UI (panel/suggestion) disabled; blink provides completions
- Scoped to code buffers; skips special buffers and huge files
}}}1 --]]

local is_large = function(buf)
  local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
  return ok and stats and stats.size and stats.size > (vim.g.large_file_threshold_bytes or 200*1024)
end
-- use is_large to disable heavy features per buffer

return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',            -- allow manual :Copilot auth/status
  event = 'InsertEnter',      -- load when editing starts

  -- Options {{{1
  opts = {
    -- Disable Copilot UI (blink-cmp-copilot will surface items)
    suggestion = { enabled = false },
    panel = { enabled = false },

    -- Filetype gating: keep Copilot out of non-code/special buffers
    filetypes = {
      ['.'] = false,               -- unknown/empty
      help = false,
      text = false,
      markdown = false,            -- set true if you want prose assistance
      gitcommit = false,
      gitrebase = false,
      NeogitCommitMessage = false,
      TelescopePrompt = false,
      ['neo-tree'] = false,
      ['dap-repl'] = false,
      ['terminal'] = false,

      -- enable common code ft (true is implicit, listed here for clarity)
      lua = true,
      python = true,
      javascript = true,
      typescript = true,
      tsx = true,
      jsx = true,
      go = true,
      rust = true,
      sh = true,
      bash = true,
      zsh = true,
      dockerfile = true,
      yaml = true,
      json = true,
      html = true,
      css = true,
    },

    -- Large-file guard: don’t attach Copilot for very big files
    server_opts_overrides = {
      -- Copilot respects root_dir; no heavy settings needed here,
      -- but we can cheaply skip giant buffers at attach time:
      on_attach = function(client, bufnr)
        if is_large(bufnr) then
          client.stop()
        end
      end,
    },
  },
  -- }}}1

  -- Notes:
  -- - blink.lua already integrates 'blink-cmp-copilot' as a source.
  -- - Keeping suggestion/panel disabled avoids duplicate UI and saves CPU.
}
