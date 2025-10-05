-- vim: foldmethod=marker foldlevel=1

--[[ Python Filetype Configuration {{{1
Enhanced editing experience for Python files with PEP 8 compliance,
smart execution, virtual environment detection, and development tools.
}}}1 --]]

-- Python Settings {{{1
-- PEP 8 compliant indentation
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.tabstop = 4
vim.opt_local.expandtab = true
vim.opt_local.smartindent = true

-- Python-specific options
vim.opt_local.textwidth = 88
vim.opt_local.colorcolumn = '89'
vim.opt_local.foldmethod = 'indent'
vim.opt_local.foldlevel = 2

-- Show whitespace (important for Python)
vim.opt_local.list = true
vim.opt_local.listchars = { tab = '→ ', trail = '·', nbsp = '⦸' }
-- }}}1

-- Python Execution {{{1
local function get_python_command()
  -- Virtual environment
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. '/bin/python'
  end

  -- Project-specific
  local venv_paths = { '.venv/bin/python', 'venv/bin/python' }
  for _, path in ipairs(venv_paths) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end

  -- System fallback
  return vim.fn.executable('python3') == 1 and 'python3' or 'python'
end

local function run_python_file()
  local filepath = vim.fn.expand('%:p')

  if vim.bo.modified then
    vim.cmd('write')
  end

  local python_cmd = get_python_command()
  local cmd = string.format('%s "%s"', python_cmd, filepath)
  local shell_cmd = string.format('echo "Running: %s" && %s; echo ""; read -p "Press Enter to continue..."',
                                  vim.fn.expand('%:t'), cmd)

  -- Create terminal
  vim.cmd('botright new')
  vim.api.nvim_win_set_height(0, 14)
  vim.wo.winfixheight = true
  vim.fn.termopen(shell_cmd)
  vim.cmd('startinsert')
end

local function run_python_selection()
  local python_cmd = get_python_command()
  local mode = vim.fn.mode()
  local text

  if mode == 'v' or mode == 'V' then
    vim.cmd('normal! "vy')
    text = vim.fn.getreg('v')
  else
    text = vim.fn.getline('.')
  end

  if vim.trim(text) == '' then
    vim.notify('No code to execute', vim.log.levels.WARN)
    return
  end

  local temp_file = vim.fn.tempname() .. '.py'
  vim.fn.writefile(vim.split(text, '\n'), temp_file)

  vim.cmd('botright 10split | terminal ' .. python_cmd .. ' "' .. temp_file .. '"')
  vim.cmd('startinsert')
end
-- }}}1

-- Development Tools {{{1
local function add_import()
  vim.ui.input({ prompt = 'Import: ' }, function(input)
    if input and input ~= '' then
      vim.api.nvim_buf_set_lines(0, 0, 0, false, { input })
      vim.notify('Added: ' .. input, vim.log.levels.INFO)
    end
  end)
end

local function format_with_black()
  if vim.fn.executable('black') == 1 then
    vim.cmd('!black "%"')
    vim.cmd('edit!')
  else
    vim.notify('black not available', vim.log.levels.WARN)
  end
end

local function toggle_breakpoint()
  local line = vim.fn.getline('.')
  if line:match('import pdb') then
    vim.cmd('normal! dd')
  else
    vim.cmd('normal! Oimport pdb; pdb.set_trace()<Esc>')
  end
end
-- }}}1

-- Key Mappings {{{1
-- Execution
vim.keymap.set('n', '<leader>pr', run_python_file, { buffer = true, desc = 'Run Python file' })
vim.keymap.set('n', '<leader>pl', run_python_selection, { buffer = true, desc = 'Run current line' })
vim.keymap.set('v', '<leader>pr', run_python_selection, { buffer = true, desc = 'Run selection' })

-- Development
vim.keymap.set('n', '<leader>pi', add_import, { buffer = true, desc = 'Add import' })
vim.keymap.set('n', '<leader>pf', format_with_black, { buffer = true, desc = 'Format with black' })
vim.keymap.set('n', '<leader>pb', toggle_breakpoint, { buffer = true, desc = 'Toggle breakpoint' })

-- Navigation
vim.keymap.set('n', ']]', '/^\\s*\\(def\\|class\\) <CR>', { buffer = true, desc = 'Next function/class' })
vim.keymap.set('n', '[[', '?^\\s*\\(def\\|class\\) <CR>', { buffer = true, desc = 'Previous function/class' })

-- Quick docstring
vim.keymap.set('n', '<leader>pd', function()
  local line = vim.fn.getline('.')
  if line:match('^%s*def ') or line:match('^%s*class ') then
    vim.cmd('normal! o"""<CR><CR>"""<Esc>ki    ')
    vim.cmd('startinsert!')
  end
end, { buffer = true, desc = 'Add docstring' })
-- }}}1
