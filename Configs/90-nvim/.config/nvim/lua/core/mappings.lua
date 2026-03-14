-- vim: foldmethod=marker foldlevel=1

-- Core Key Mappings Configuration — Essential key mappings organized by category for easy maintenance. {{{1
-- }}}1

-- Core Editor Functions  {{{1
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', { desc = 'Save file' })
vim.keymap.set('i', '<C-s>', '<Esc><cmd>w<CR>a', { desc = 'Save file (insert mode)' })
-- }}}1

-- Window Navigation {{{1
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move to left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move to right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move to lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move to upper window' })

-- Window resizing
vim.keymap.set('n', '<C-Up>', '<cmd>resize +2<CR>', { desc = 'Increase height' })
vim.keymap.set('n', '<C-Down>', '<cmd>resize -2<CR>', { desc = 'Decrease height' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -2<CR>', { desc = 'Decrease width' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +2<CR>', { desc = 'Increase width' })
-- }}}1

-- Buffer Management {{{1
vim.keymap.set('n', '<leader>bn', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<leader>bb', '<cmd>e #<CR>', { desc = 'Switch to other buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>bD', '<cmd>bdelete!<CR>', { desc = 'Force delete buffer' })
vim.keymap.set('n', '<leader>b', '<cmd>enew<CR>', { desc = 'New buffer' })
-- }}}1

-- Text Manipulation {{{1
-- Better indenting
vim.keymap.set('v', '<', '<gv', { desc = 'Indent left and reselect' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right and reselect' })

-- Move lines
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { desc = 'Move line down' })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { desc = 'Move line up' })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Better paste
vim.keymap.set('v', 'p', '"_dP', { desc = 'Paste without yanking' })

-- Center screen on navigation
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down and center' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up and center' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next search and center' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous search and center' })
-- }}}1

-- Comments {{{1
vim.keymap.set('n', '<leader>/', 'gcc', { desc = 'Toggle comment line', remap = true })
vim.keymap.set('v', '<leader>/', 'gc', { desc = 'Toggle comment selection', remap = true })
-- }}}1

-- Toggle Functions {{{1
vim.keymap.set('n', '<leader>tn', '<cmd>set number!<CR>', { desc = 'Toggle line numbers' })
vim.keymap.set('n', '<leader>tr', '<cmd>set relativenumber!<CR>', { desc = 'Toggle relative numbers' })
vim.keymap.set('n', '<leader>tw', '<cmd>set wrap!<CR>', { desc = 'Toggle line wrap' })
vim.keymap.set('n', '<leader>ts', '<cmd>set spell!<CR>', { desc = 'Toggle spell check' })
vim.keymap.set('n', '<leader>tl', '<cmd>set list!<CR>', { desc = 'Toggle whitespace display' })

-- Distraction-free mode - toggle all visual elements
vim.keymap.set('n', '<leader>ta', function()
  -- Store initial state on first toggle
  if vim.g.distraction_free_state == nil then
    -- Store ibl config if plugin is available
    local ibl_config = {}
    pcall(function()
      local ibl = require 'ibl'
      ibl_config = ibl.config
    end)

    vim.g.distraction_free_state = {
      number = vim.wo.number,
      relativenumber = vim.wo.relativenumber,
      signcolumn = vim.wo.signcolumn,
      foldcolumn = vim.wo.foldcolumn,
      list = vim.wo.list,
      cursorline = vim.wo.cursorline,
      cursorcolumn = vim.wo.cursorcolumn,
      colorcolumn = vim.wo.colorcolumn,
      showmode = vim.o.showmode,
      showcmd = vim.o.showcmd,
      laststatus = vim.o.laststatus,
      showtabline = vim.o.showtabline,
      ruler = vim.o.ruler,
      cmdheight = vim.o.cmdheight,
      diagnostics_enabled = vim.diagnostic.is_enabled(),
      diagnostic_config = vim.diagnostic.config(),
      ibl_config = ibl_config,
    }
    vim.g.distraction_free_active = false
  end

  if not vim.g.distraction_free_active then
    -- Hide all visual elements
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = 'no'
    vim.wo.foldcolumn = '0'
    vim.wo.list = false
    vim.wo.cursorline = false
    vim.wo.cursorcolumn = false
    vim.wo.colorcolumn = ''
    vim.o.showmode = false
    vim.o.showcmd = false
    vim.o.laststatus = 0  -- Hide statusline
    vim.o.showtabline = 0 -- Hide tabline
    vim.o.ruler = false
    vim.o.cmdheight = 1   -- Minimal command height

    -- Disable diagnostics completely
    vim.diagnostic.enable(false)

    -- Hide all virtual text and signs
    vim.diagnostic.config {
      virtual_text = false,
      signs = false,
      underline = false,
      update_in_insert = false,
      severity_sort = false,
    }

    -- Hide gitgutter/gitsigns
    pcall(function()
      vim.cmd 'GitGutterDisable'
    end)
    pcall(function()
      vim.cmd 'Gitsigns toggle_signs'
    end)

    -- Disable Snacks indent guides
    pcall(function()
      require('snacks').indent.disable()
    end)

    -- Disable nvim-ufo visual indicators (but don't change fold state)
    pcall(function()
      local ok, ufo = pcall(require, 'ufo')
      if ok then
        -- Disable ufo without closing folds
        require('ufo.config.enable')._enable = false
      end
    end)

    -- Hide indent guides - comprehensive approach
    pcall(function()
      vim.cmd 'IBLDisable'
    end)
    pcall(function()
      vim.cmd 'IndentBlanklineDisable'
    end)
    pcall(function()
      local ibl = require 'ibl'
      ibl.setup({ enabled = false })
      ibl.setup_buffer(0, { enabled = false })
    end)

    -- Disable Treesitter indent rendering
    pcall(function()
      local ts_indent_ok, ts_indent = pcall(require, 'nvim-treesitter.indent')
      if ts_indent_ok then
        vim.b.treesitter_indent_enabled = false
      end
    end)

    -- Clear all extmarks (virtual text from any source)
    local ns_ids = vim.api.nvim_get_namespaces()
    for ns_name, ns_id in pairs(ns_ids) do
      pcall(function()
        vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
      end)
    end

    -- Hide other virtual text sources
    pcall(function()
      vim.cmd 'LspVirtualTextToggle'
    end)

    vim.g.distraction_free_active = true
    vim.notify('Distraction-free mode: ON', vim.log.levels.INFO)
  else
    -- Restore all visual elements
    local state = vim.g.distraction_free_state
    vim.wo.number = state.number
    vim.wo.relativenumber = state.relativenumber
    vim.wo.signcolumn = state.signcolumn
    vim.wo.foldcolumn = state.foldcolumn
    vim.wo.list = state.list
    vim.wo.cursorline = state.cursorline
    vim.wo.cursorcolumn = state.cursorcolumn
    vim.wo.colorcolumn = state.colorcolumn
    vim.o.showmode = state.showmode
    vim.o.showcmd = state.showcmd
    vim.o.laststatus = state.laststatus
    vim.o.showtabline = state.showtabline
    vim.o.ruler = state.ruler
    vim.o.cmdheight = state.cmdheight

    -- Restore diagnostics
    vim.diagnostic.enable(state.diagnostics_enabled)
    vim.diagnostic.config(state.diagnostic_config)

    -- Restore gitgutter/gitsigns
    pcall(function()
      vim.cmd 'GitGutterEnable'
    end)
    pcall(function()
      vim.cmd 'Gitsigns toggle_signs'
    end)

    -- Re-enable Snacks indent guides
    pcall(function()
      require('snacks').indent.enable()
    end)

    -- Re-enable nvim-ufo visual indicators (without changing fold state)
    pcall(function()
      local ok, ufo = pcall(require, 'ufo')
      if ok then
        require('ufo.config.enable')._enable = true
      end
    end)

    -- Restore indent guides - comprehensive approach
    pcall(function()
      vim.cmd 'IBLEnable'
    end)
    pcall(function()
      vim.cmd 'IndentBlanklineEnable'
    end)
    pcall(function()
      local ibl = require 'ibl'
      if state.ibl_config and next(state.ibl_config) then
        ibl.setup(state.ibl_config)
      else
        ibl.setup({ enabled = true })
      end
      ibl.setup_buffer(0, { enabled = true })
    end)

    -- Re-enable Treesitter indent rendering
    pcall(function()
      vim.b.treesitter_indent_enabled = true
    end)

    -- Restore other virtual text sources
    pcall(function()
      vim.cmd 'LspVirtualTextToggle'
    end)

    vim.g.distraction_free_active = false
    vim.notify('Distraction-free mode: OFF', vim.log.levels.INFO)
  end
end, { desc = 'Toggle distraction-free mode (hide all visual elements)' })
-- }}}1

-- Diagnostics {{{1
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostic quickfix list' })
vim.keymap.set('n', '<leader>df', vim.diagnostic.open_float, { desc = 'Show diagnostic float' })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
-- }}}1

-- Quick Utilities {{{1
vim.keymap.set('n', '<leader>qq', '<cmd>qa<CR>', { desc = 'Quit all' })
vim.keymap.set('n', '<leader>rr', '<cmd>source $MYVIMRC<CR>', { desc = 'Reload config' })
vim.keymap.set('n', '<leader>ei', '<cmd>edit $MYVIMRC<CR>', { desc = 'Edit init.lua' })
-- }}}1

-- Clipboard {{{1
-- Filter virtual text from clipboard on yank operations
-- Ensures that indent guides, diagnostics, LSP hints, etc. are never copied
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('ClipboardFilter', { clear = true }),
  callback = function(ev)
    -- Only process clipboard register operations
    if vim.v.event.regname ~= '' and vim.v.event.regname ~= '+' and vim.v.event.regname ~= '*' then
      return
    end

    -- Get the yank operator type and register
    local reg_name = vim.v.event.regname or '+'
    if reg_name == '' then
      reg_name = '+'
    end

    -- Get the text that was yanked
    local lines = vim.v.event.regcontents

    if not lines or #lines == 0 then
      return
    end

    -- Process lines to remove virtual text indicators
    -- This handles: indent guides │, diagnostics, LSP hints, etc.
    local cleaned_lines = {}
    for _, line in ipairs(lines) do
      -- Remove common virtual text characters used by indent plugins
      -- │ (box drawing light vertical) - indent guides
      -- ▁ ▂ ▃ ▄ ▅ ▆ ▇ █ (block elements) - various indicators
      local cleaned = line
        :gsub('│', '')   -- Indent guides
        :gsub('▏', '')   -- Vertical bar
        :gsub('▎', '')   -- Vertical bar
        :gsub('▍', '')   -- Vertical bar
        :gsub('▌', '')   -- Vertical bar
        :gsub('▋', '')   -- Vertical bar
        :gsub('▊', '')   -- Vertical bar
        :gsub('▉', '')   -- Vertical bar
        :gsub('█', '')   -- Full block
        :gsub('┃', '')   -- Box drawing
        :gsub('┆', '')   -- Box drawing
        :gsub('┇', '')   -- Box drawing
        :gsub('⎪', '')   -- Terminal box drawing
        -- Trim trailing whitespace that might be left after removing guides
        :gsub('%s+$', '')

      table.insert(cleaned_lines, cleaned)
    end

    -- Set the cleaned content back to the register
    vim.fn.setreg(reg_name, cleaned_lines, vim.v.event.regtype)
  end,
  desc = 'Remove virtual text from clipboard on yank'
})
-- }}}1
