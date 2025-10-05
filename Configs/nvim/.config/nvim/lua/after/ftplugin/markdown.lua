-- vim: foldmethod=marker foldlevel=1

--[[ Markdown Configuration {{{1
Enhanced editing experience for Markdown files with live preview,
table editing, link management, formatting tools, and productivity features.
}}}1 --]]

-- Markdown Settings {{{1
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true
vim.opt_local.smartindent = false  -- Disable for better markdown flow
vim.opt_local.autoindent = true

-- Markdown-specific options
vim.opt_local.textwidth = 80
vim.opt_local.colorcolumn = '81'
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt_local.foldlevel = 1

-- Enable spell checking
vim.opt_local.spell = true
vim.opt_local.spelllang = 'en_us'
vim.opt_local.spellcapcheck = ''  -- Don't check capitalization at start of sentence

-- Conceal settings for better readability
vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = 'nc'

-- Show whitespace selectively
vim.opt_local.list = true
vim.opt_local.listchars = {
  trail = '·',
  nbsp = '⦸',
  extends = '❯',
  precedes = '❮',
}

-- Detect markdown variant
local function detect_markdown_variant()
  local filename = vim.fn.expand('%:t')
  local filepath = vim.fn.expand('%:p')

  if filename:match('README%.md$') then
    vim.b.markdown_type = 'readme'
  elseif filepath:match('/docs/') or filepath:match('/documentation/') then
    vim.b.markdown_type = 'documentation'
  elseif filename:match('%.wiki%.md$') then
    vim.b.markdown_type = 'wiki'
  elseif filepath:match('/blog/') or filepath:match('/posts/') then
    vim.b.markdown_type = 'blog'
  else
    vim.b.markdown_type = 'general'
  end
end

detect_markdown_variant()
-- }}}1

-- Smart Markdown Mappings {{{1
-- Quick formatting
vim.keymap.set('n', '<leader>mb', 'ciw**<C-r>"**<Esc>', { buffer = true, desc = 'Bold word' })
vim.keymap.set('v', '<leader>mb', 'c**<C-r>"**<Esc>', { buffer = true, desc = 'Bold selection' })
vim.keymap.set('n', '<leader>mi', 'ciw*<C-r>"*<Esc>', { buffer = true, desc = 'Italic word' })
vim.keymap.set('v', '<leader>mi', 'c*<C-r>"*<Esc>', { buffer = true, desc = 'Italic selection' })
vim.keymap.set('n', '<leader>mc', 'ciw`<C-r>"`<Esc>', { buffer = true, desc = 'Code word' })
vim.keymap.set('v', '<leader>mc', 'c`<C-r>"`<Esc>', { buffer = true, desc = 'Code selection' })
vim.keymap.set('n', '<leader>ms', 'ciw~~<C-r>"~~<Esc>', { buffer = true, desc = 'Strikethrough word' })
vim.keymap.set('v', '<leader>ms', 'c~~<C-r>"~~<Esc>', { buffer = true, desc = 'Strikethrough selection' })

-- Header creation
vim.keymap.set('n', '<leader>m1', 'I# <Esc>', { buffer = true, desc = 'H1 header' })
vim.keymap.set('n', '<leader>m2', 'I## <Esc>', { buffer = true, desc = 'H2 header' })
vim.keymap.set('n', '<leader>m3', 'I### <Esc>', { buffer = true, desc = 'H3 header' })
vim.keymap.set('n', '<leader>m4', 'I#### <Esc>', { buffer = true, desc = 'H4 header' })
vim.keymap.set('n', '<leader>m5', 'I##### <Esc>', { buffer = true, desc = 'H5 header' })
vim.keymap.set('n', '<leader>m6', 'I###### <Esc>', { buffer = true, desc = 'H6 header' })

-- List creation
vim.keymap.set('i', '<C-l>', function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, col)
  local indent = before_cursor:match('^%s*')

  if vim.trim(before_cursor) == '' then
    return '- '
  elseif before_cursor:match('%s*[%-%*%+]%s*$') then
    return '\n' .. indent .. '- '
  elseif before_cursor:match('%s*%d+%.%s*$') then
    local num = before_cursor:match('(%d+)%.%s*$')
    return '\n' .. indent .. (tonumber(num) + 1) .. '. '
  else
    return '\n' .. indent .. '- '
  end
end, { buffer = true, expr = true, desc = 'Smart list item' })

-- Link creation
vim.keymap.set('i', '<C-k>', function()
  return '[]() '
end, { buffer = true, expr = true, desc = 'Insert link' })

vim.keymap.set('n', '<leader>ml', function()
  vim.ui.input({ prompt = 'Link URL: ' }, function(url)
    if url then
      vim.ui.input({ prompt = 'Link text (empty for current word): ' }, function(text)
        if text == '' then
          -- Use current word
          vim.cmd('normal! ciw[' .. vim.fn.expand('<cword>') .. '](' .. url .. ')')
        else
          vim.cmd('normal! a[' .. text .. '](' .. url .. ')')
        end
      end)
    end
  end)
end, { buffer = true, desc = 'Create link' })

-- Table management
vim.keymap.set('n', '<leader>mt', function()
  vim.ui.input({ prompt = 'Number of columns: ' }, function(cols)
    if cols then
      local num_cols = tonumber(cols) or 2
      local header = '|'
      local separator = '|'

      for i = 1, num_cols do
        header = header .. ' Header ' .. i .. ' |'
        separator = separator .. ' --- |'
      end

      local table_lines = { header, separator }
      for i = 1, 3 do -- Add 3 data rows
        local row = '|'
        for j = 1, num_cols do
          row = row .. '  |'
        end
        table.insert(table_lines, row)
      end

      vim.api.nvim_put(table_lines, 'l', true, true)
    end
  end)
end, { buffer = true, desc = 'Create table' })

-- Navigation mappings
vim.keymap.set('n', ']]', '/^#\\+<CR>', { buffer = true, desc = 'Next header' })
vim.keymap.set('n', '[[', '?^#\\+<CR>', { buffer = true, desc = 'Previous header' })
vim.keymap.set('n', '}', '/^```<CR>', { buffer = true, desc = 'Next code block' })
vim.keymap.set('n', '{', '?^```<CR>', { buffer = true, desc = 'Previous code block' })
-- }}}1

-- Markdown Tools and Validation {{{1
local function create_table_of_contents()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local toc = { '## Table of Contents', '' }

  for i, line in ipairs(lines) do
    local level, title = line:match('^(#+)%s+(.+)$')
    if level and #level <= 6 then
      local indent = string.rep('  ', #level - 1)
      local anchor = title:lower():gsub('%s+', '-'):gsub('[^%w%-]', '')
      table.insert(toc, indent .. '- [' .. title .. '](#' .. anchor .. ')')
    end
  end

  table.insert(toc, '')
  vim.api.nvim_put(toc, 'l', true, true)
end

local function format_table()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Find table boundaries
  local table_start, table_end
  for i = cursor_line, 1, -1 do
    if lines[i] and lines[i]:match('^%s*|') then
      table_start = i
    else
      break
    end
  end

  for i = cursor_line, #lines do
    if lines[i] and lines[i]:match('^%s*|') then
      table_end = i
    else
      break
    end
  end

  if not table_start or not table_end then
    vim.notify('No table found at cursor', vim.log.levels.WARN)
    return
  end

  -- Extract table data
  local table_lines = vim.list_slice(lines, table_start, table_end)
  local columns = {}
  local max_widths = {}

  for _, line in ipairs(table_lines) do
    local row = {}
    for cell in line:gmatch('|([^|]*)') do
      table.insert(row, vim.trim(cell))
    end
    table.insert(columns, row)

    -- Calculate max widths
    for j, cell in ipairs(row) do
      max_widths[j] = math.max(max_widths[j] or 0, #cell)
    end
  end

  -- Format table
  local formatted = {}
  for i, row in ipairs(columns) do
    local formatted_row = '|'
    for j, cell in ipairs(row) do
      local width = max_widths[j] or #cell
      if i == 2 and cell:match('^%-+$') then
        -- Separator row
        formatted_row = formatted_row .. ' ' .. string.rep('-', width) .. ' |'
      else
        formatted_row = formatted_row .. ' ' .. cell .. string.rep(' ', width - #cell) .. ' |'
      end
    end
    table.insert(formatted, formatted_row)
  end

  vim.api.nvim_buf_set_lines(0, table_start - 1, table_end, false, formatted)
end

local function lint_markdown()
  local run = require('core.extras.utility').run
  local current_file = vim.fn.expand('%:p')

  if vim.fn.executable('markdownlint') == 1 then
    run({ 'markdownlint', current_file },
      function() vim.notify('✓ Markdown passes linting', vim.log.levels.INFO) end,
      function(err) vim.notify('Markdown linting issues:\n' .. err, vim.log.levels.WARN) end)
  else
    vim.notify('markdownlint not available. Install with: npm install -g markdownlint-cli', vim.log.levels.ERROR)
  end
end

local function check_links()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local issues = {}

  for i, line in ipairs(lines) do
    -- Check for broken reference links
    for link_ref in line:gmatch('%[([^%]]+)%]%[([^%]]+)%]') do
      -- This is a basic check - could be enhanced
    end

    -- Check for empty links
    if line:match('%[.-%]%(%)') then
      table.insert(issues, string.format('Line %d: Empty link URL', i))
    end

    -- Check for malformed links
    if line:match('%[.-%]%([^%)]*[%s][^%)]*%)') then
      table.insert(issues, string.format('Line %d: Link URL contains spaces', i))
    end
  end

  if #issues == 0 then
    vim.notify('✓ No link issues found', vim.log.levels.INFO)
  else
    vim.notify('Link issues:\n' .. table.concat(issues, '\n'), vim.log.levels.WARN)
  end
end

local function word_count()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, '\n')

  -- Remove markdown syntax
  content = content:gsub('%*%*(.-)%*%*', '%1')  -- Bold
  content = content:gsub('%*(.-)%*', '%1')      -- Italic
  content = content:gsub('`(.-)`', '%1')        -- Code
  content = content:gsub('%[(.-)%]%(.-%)', '%1') -- Links
  content = content:gsub('^#+%s+', '', 'm')     -- Headers
  content = content:gsub('^%s*[%-%*%+]%s+', '', 'm') -- Lists
  content = content:gsub('^%s*%d+%.%s+', '', 'm')    -- Numbered lists

  local words = 0
  local chars = 0
  local lines_count = #lines

  for word in content:gmatch('%S+') do
    words = words + 1
  end

  chars = #content:gsub('%s', '')

  vim.notify(string.format('Words: %d | Characters: %d | Lines: %d', words, chars, lines_count), vim.log.levels.INFO)
end

local function preview_markdown()
  local current_file = vim.fn.expand('%:p')

  if vim.fn.executable('pandoc') == 1 then
    local html_file = vim.fn.tempname() .. '.html'
    local cmd = 'pandoc -f markdown -t html -s "' .. current_file .. '" -o "' .. html_file .. '"'
    vim.fn.system(cmd)

    if vim.v.shell_error == 0 then
      -- Open in browser
      if vim.fn.has('macunix') == 1 then
        vim.fn.system('open "' .. html_file .. '"')
      elseif vim.fn.has('unix') == 1 then
        vim.fn.system('xdg-open "' .. html_file .. '"')
      end
      vim.notify('Preview opened in browser', vim.log.levels.INFO)
    else
      vim.notify('Failed to generate preview', vim.log.levels.ERROR)
    end
  else
    vim.notify('pandoc not available for preview', vim.log.levels.ERROR)
  end
end

-- Markdown tool mappings
vim.keymap.set('n', '<leader>mT', create_table_of_contents, { buffer = true, desc = 'Create TOC' })
vim.keymap.set('n', '<leader>mf', format_table, { buffer = true, desc = 'Format table' })
vim.keymap.set('n', '<leader>mv', lint_markdown, { buffer = true, desc = 'Lint markdown' })
vim.keymap.set('n', '<leader>mL', check_links, { buffer = true, desc = 'Check links' })
vim.keymap.set('n', '<leader>mw', word_count, { buffer = true, desc = 'Word count' })
vim.keymap.set('n', '<leader>mp', preview_markdown, { buffer = true, desc = 'Preview in browser' })
-- }}}1

-- Markdown Snippets {{{1
-- Set up snippet integration if LuaSnip is available
local ok, luasnip = pcall(require, 'luasnip')
if ok then
  luasnip.add_snippets('markdown', {
    luasnip.snippet('link', {
      luasnip.text_node('['),
      luasnip.insert_node(1, 'text'),
      luasnip.text_node(']('),
      luasnip.insert_node(2, 'url'),
      luasnip.text_node(')'),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('img', {
      luasnip.text_node('!['),
      luasnip.insert_node(1, 'alt text'),
      luasnip.text_node(']('),
      luasnip.insert_node(2, 'image url'),
      luasnip.text_node(')'),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('code', {
      luasnip.text_node({'```'}),
      luasnip.insert_node(1, 'language'),
      luasnip.text_node({'', ''}),
      luasnip.insert_node(2, 'code'),
      luasnip.text_node({'', '```'}),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('table', {
      luasnip.text_node('| '),
      luasnip.insert_node(1, 'Header 1'),
      luasnip.text_node(' | '),
      luasnip.insert_node(2, 'Header 2'),
      luasnip.text_node({' |', '| --- | --- |', '| '}),
      luasnip.insert_node(3, 'Cell 1'),
      luasnip.text_node(' | '),
      luasnip.insert_node(4, 'Cell 2'),
      luasnip.text_node(' |'),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('details', {
      luasnip.text_node('<details>'),
      luasnip.text_node({'', '<summary>'}),
      luasnip.insert_node(1, 'Summary'),
      luasnip.text_node({'</summary>', '', ''}),
      luasnip.insert_node(2, 'Content'),
      luasnip.text_node({'', '</details>'}),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('frontmatter', {
      luasnip.text_node({'---', 'title: '}),
      luasnip.insert_node(1, 'Title'),
      luasnip.text_node({'', 'date: '}),
      luasnip.insert_node(2, os.date('%Y-%m-%d')),
      luasnip.text_node({'', 'tags: ['}),
      luasnip.insert_node(3, 'tag1, tag2'),
      luasnip.text_node({']', '---', ''}),
      luasnip.insert_node(0),
    }),
  })
end
-- }}}1

-- Markdown Auto Commands {{{1
-- Auto-format tables on save
vim.api.nvim_create_autocmd('BufWritePre', {
  buffer = 0,
  callback = function()
    if vim.g.markdown_auto_format_tables then
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

      for i, line in ipairs(lines) do
        if line:match('^%s*|.*|%s*$') then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          format_table()
          break
        end
      end

      vim.api.nvim_win_set_cursor(0, cursor_pos)
    end
  end,
  desc = 'Auto-format tables on save'
})

-- Smart enter in lists
vim.api.nvim_create_autocmd('InsertEnter', {
  buffer = 0,
  callback = function()
    vim.keymap.set('i', '<CR>', function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local before_cursor = line:sub(1, col)

      -- Check if we're in a list item
      if before_cursor:match('^%s*[%-%*%+]%s*$') then
        -- Empty list item, remove it
        return '<BS><BS>'
      elseif before_cursor:match('^%s*%d+%.%s*$') then
        -- Empty numbered list item, remove it
        local spaces = before_cursor:match('^(%s*)')
        return string.rep('<BS>', #before_cursor - #spaces)
      else
        return '<CR>'
      end
    end, { buffer = true, expr = true })
  end,
  desc = 'Smart enter in markdown lists'
})

-- Auto-save for live preview
vim.api.nvim_create_autocmd('TextChanged', {
  buffer = 0,
  callback = function()
    if vim.g.markdown_auto_save then
      vim.cmd('silent write')
    end
  end,
  desc = 'Auto-save for live preview'
})

-- Spell check configuration
vim.api.nvim_create_autocmd('BufEnter', {
  buffer = 0,
  callback = function()
    -- Don't spell check code blocks and URLs
    vim.cmd([[
      syntax match markdownCodeBlock /```\_.\{-}```/ contains=@NoSpell
      syntax match markdownCode /`.\{-}`/ contains=@NoSpell
      syntax match markdownUrl /https\?:\/\/\S\+/ contains=@NoSpell
    ]])
  end,
  desc = 'Configure spell checking for markdown'
})
-- }}}1

-- Markdown Commands {{{1
vim.api.nvim_create_user_command('MarkdownPreview', function()
  preview_markdown()
end, { desc = 'Preview markdown in browser' })

vim.api.nvim_create_user_command('MarkdownTOC', function()
  create_table_of_contents()
end, { desc = 'Generate table of contents' })

vim.api.nvim_create_user_command('MarkdownLint', function()
  lint_markdown()
end, { desc = 'Lint markdown file' })

vim.api.nvim_create_user_command('MarkdownWordCount', function()
  word_count()
end, { desc = 'Show word count statistics' })

vim.api.nvim_create_user_command('MarkdownFormatTable', function()
  format_table()
end, { desc = 'Format table at cursor' })

vim.api.nvim_create_user_command('MarkdownCheckLinks', function()
  check_links()
end, { desc = 'Check for link issues' })

-- Export commands
vim.api.nvim_create_user_command('MarkdownToPDF', function()
  if vim.fn.executable('pandoc') == 1 then
    local current_file = vim.fn.expand('%:p')
    local pdf_file = vim.fn.expand('%:r') .. '.pdf'
    local cmd = 'pandoc "' .. current_file .. '" -o "' .. pdf_file .. '"'
    vim.fn.system(cmd)

    if vim.v.shell_error == 0 then
      vim.notify('Exported to ' .. pdf_file, vim.log.levels.INFO)
    else
      vim.notify('Failed to export PDF', vim.log.levels.ERROR)
    end
  end
end, { desc = 'Export markdown to PDF' })

vim.api.nvim_create_user_command('MarkdownToHTML', function()
  if vim.fn.executable('pandoc') == 1 then
    local current_file = vim.fn.expand('%:p')
    local html_file = vim.fn.expand('%:r') .. '.html'
    local cmd = 'pandoc -f markdown -t html -s "' .. current_file .. '" -o "' .. html_file .. '"'
    vim.fn.system(cmd)

    if vim.v.shell_error == 0 then
      vim.notify('Exported to ' .. html_file, vim.log.levels.INFO)
    else
      vim.notify('Failed to export HTML', vim.log.levels.ERROR)
    end
  end
end, { desc = 'Export markdown to HTML' })
-- }}}1