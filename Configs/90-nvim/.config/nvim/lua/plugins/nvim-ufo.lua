-- vim: foldmethod=marker foldlevel=1

--[[ nvim-ufo — modern folding UI with virtual text {{{1
Performance-oriented setup:
- Lazy-loads on file open (BufReadPost)
- Prefers Treesitter folds, falls back to indent
- Skips huge files and special buffers
- Keeps your custom foldtext fallback for non-ufo scenarios
}}}1 --]]

pcall(function()
  if vim.g.have_nerd_font then
    vim.opt.fillchars:append({ foldopen = '', foldclose = '', fold = ' ' })
  else
    vim.opt.fillchars:append({ fold = ' ' })
  end
end)

return {
  'kevinhwang91/nvim-ufo',
  enabled = true,
  dependencies = { 'kevinhwang91/promise-async' },

  -- Load when a real file is opened; avoids startup cost
  event = 'BufReadPost',

  -- Options {{{1
  opts = {
    -- Decide per-buffer providers; Treesitter first, then indent
    provider_selector = function(bufnr, filetype, buftype)
      -- Skip special buffers
      if buftype == 'nofile' or buftype == 'prompt' or buftype == 'terminal' then
        return { 'indent' }
      end

      -- Large-file guard (aligns with core/options.lua)
      local limit = tonumber(vim.g.large_file_threshold_bytes or 200 * 1024)
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= '' and limit then
        local stat = vim.uv.fs_stat(name)
        if stat and stat.size and stat.size > limit then
          return { 'indent' }
        end
      end

      -- Prefer Treesitter if available; indent otherwise
      local ok_ts, ts = pcall(require, 'vim.treesitter')
      if ok_ts then
        local has_parser = pcall(function() ts.get_parser(bufnr) end)
        if has_parser then
          return { 'treesitter', 'indent' }
        end
      end
      return { 'indent' }
    end,

    -- Keep it snappy; avoid long highlight flashes
    open_fold_hl_timeout = 50,
  },
  -- }}}1

  -- Setup {{{1
  config = function(_, opts)
    local ok, ufo = pcall(require, 'ufo')
    if not ok then return end
    ufo.setup(opts)

    -- Convenience keymaps; defer function lookup to runtime
    vim.keymap.set('n', 'zR', function() require('ufo').openAllFolds() end, { desc = 'UFO: open all folds' })
    vim.keymap.set('n', 'zM', function() require('ufo').closeAllFolds() end, { desc = 'UFO: close all folds' })
    -- Optional: more granular
    -- vim.keymap.set('n', 'zr', function() require('ufo').openFoldsExceptKinds() end, { desc = 'UFO: open folds except kinds' })
    -- vim.keymap.set('n', 'zm', function() require('ufo').closeFoldsWith() end, { desc = 'UFO: close folds with level' })
  end,
  -- }}}1
}