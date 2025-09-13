-- vim: foldmethod=marker foldlevel=1

--[[ JSON Filetype Configuration {{{1
Enhanced editing experience for JSON files with smart formatting,
validation, and navigation features.
}}}1 --]]

-- Indentation Settings {{{1
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true
vim.opt_local.smartindent = true

-- JSON-specific options
vim.opt_local.textwidth = 0
vim.opt_local.wrap = false
vim.opt_local.foldmethod = 'syntax'
vim.opt_local.foldlevel = 2
-- }}}1

-- Smart Comma Handling {{{1
local function smart_new_line()
  local line = vim.api.nvim_get_current_line()
  local trimmed = vim.trim(line)

  -- Skip if empty or already has comma/bracket
  if trimmed == '' or trimmed:match('[,{%[]%s*$') then
    return 'o'
  end

  -- Add comma for values
  if trimmed:match('["\'}%d]%s*$') or
     trimmed:match('true%s*$') or
     trimmed:match('false%s*$') or
     trimmed:match('null%s*$') then
    return 'A,<CR>'
  end

  return 'o'
end

vim.keymap.set('n', 'o', smart_new_line, {
  buffer = true,
  expr = true,
  desc = 'Smart new line with comma'
})
-- }}}1

-- JSON Operations {{{1
local function validate_json()
  local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  local ok, err = pcall(vim.json.decode, content)

  if ok then
    vim.notify('✓ Valid JSON', vim.log.levels.INFO)
  else
    vim.notify('✗ Invalid JSON: ' .. tostring(err), vim.log.levels.ERROR)
  end
end

local function format_json()
  if vim.fn.executable('jq') == 1 then
    vim.cmd(':%!jq .')
    vim.notify('Formatted with jq', vim.log.levels.INFO)
  elseif vim.fn.executable('python3') == 1 then
    pcall(vim.cmd, ':%!python3 -m json.tool')
    vim.notify('Formatted with Python', vim.log.levels.INFO)
  else
    vim.notify('No JSON formatter available', vim.log.levels.WARN)
  end
end

-- Key mappings
vim.keymap.set('n', '<leader>jv', validate_json, { buffer = true, desc = 'Validate JSON' })
vim.keymap.set('n', '<leader>jf', format_json, { buffer = true, desc = 'Format JSON' })
vim.keymap.set('n', '<leader>jq', 'ciw"<C-r>""<Esc>', { buffer = true, desc = 'Wrap in quotes' })

-- Navigation
vim.keymap.set('n', '[j', function() vim.fn.search('[{[]', 'b') end, { buffer = true, desc = 'Previous object/array' })
vim.keymap.set('n', ']j', function() vim.fn.search('[}\\]]') end, { buffer = true, desc = 'Next closing brace' })
-- }}}1

-- Enhanced Display {{{1
-- Show whitespace
vim.opt_local.list = true
vim.opt_local.listchars = { tab = '→ ', trail = '·', nbsp = '⦸' }

-- Highlight trailing commas as errors
vim.cmd([[
  highlight link jsonTrailingCommaError Error
  syntax match jsonTrailingCommaError /,\s*[}\]]/
]])

-- Performance for large files
if vim.fn.line('$') > 1000 then
  vim.opt_local.synmaxcol = 200
end
-- }}}1
