-- vim: foldmethod=marker foldlevel=1

--[[ HTML Configuration {{{1
Enhanced editing experience for HTML files with smart tag completion,
validation, formatting, accessibility checking, and productivity features.
}}}1 --]]

-- HTML Settings {{{1
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true
vim.opt_local.smartindent = true

-- HTML-specific options
vim.opt_local.textwidth = 120
vim.opt_local.colorcolumn = '121'
vim.opt_local.wrap = false
vim.opt_local.foldmethod = 'indent'
vim.opt_local.foldlevel = 2

-- Show whitespace
vim.opt_local.list = true
vim.opt_local.listchars = {
  tab = '»·',
  trail = '·',
  extends = '❯',
  precedes = '❮',
  nbsp = '⦸',
}

-- Enable spell checking for text content
vim.opt_local.spell = true
vim.opt_local.spelllang = 'en_us'

-- HTML matching pairs
vim.b.match_words = '<:>,<tag>:</tag>'

-- Detect HTML variant
local function detect_html_variant()
  local lines = vim.api.nvim_buf_get_lines(0, 0, 10, false)
  local content = table.concat(lines, '\n'):lower()

  if content:match('<!doctype html>') then
    vim.b.html_version = 'html5'
  elseif content:match('xhtml') then
    vim.b.html_version = 'xhtml'
  elseif content:match('html 4') then
    vim.b.html_version = 'html4'
  else
    vim.b.html_version = 'html5' -- default
  end
end

detect_html_variant()
-- }}}1

-- Smart HTML Mappings {{{1
-- Quick tag creation
vim.keymap.set('i', '<C-t>', function()
  local common_tags = {
    'div', 'span', 'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'a', 'img', 'ul', 'ol', 'li', 'table', 'tr', 'td', 'th',
    'form', 'input', 'button', 'select', 'option', 'textarea',
    'header', 'nav', 'main', 'section', 'article', 'aside', 'footer',
    'figure', 'figcaption', 'details', 'summary'
  }

  vim.ui.select(common_tags, {
    prompt = 'Select HTML tag:',
  }, function(choice)
    if choice then
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local before = line:sub(1, col)
      local after = line:sub(col + 1)

      vim.api.nvim_set_current_line(before .. '<' .. choice .. '></' .. choice .. '>' .. after)
      vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + #choice + 2 })
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert HTML tag' })

-- Quick attribute insertion
vim.keymap.set('i', '<C-a>', function()
  local common_attrs = {
    'id=""', 'class=""', 'style=""', 'title=""', 'alt=""',
    'src=""', 'href=""', 'target="_blank"', 'rel="noopener"',
    'data-=""', 'aria-label=""', 'role=""', 'type=""',
    'name=""', 'value=""', 'placeholder=""', 'required'
  }

  vim.ui.select(common_attrs, {
    prompt = 'Select HTML attribute:',
  }, function(choice)
    if choice then
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      vim.api.nvim_set_current_line(line:sub(1, col) .. ' ' .. choice .. line:sub(col + 1))

      -- Position cursor inside quotes if attribute has quotes
      if choice:match('=""') then
        vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + #choice })
      else
        vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + #choice + 1 })
      end
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert HTML attribute' })

-- HTML5 semantic structure
vim.keymap.set('i', '<C-s>', function()
  local structures = {
    'html5_basic', 'navigation', 'article', 'aside', 'footer_info',
    'form_contact', 'table_data', 'media_figure'
  }

  vim.ui.select(structures, {
    prompt = 'Select HTML5 structure:',
    format_item = function(item)
      return item:gsub('_', ' '):gsub('^%l', string.upper)
    end,
  }, function(choice)
    if choice then
      local indent = string.rep(' ', vim.fn.indent('.'))
      local templates = {
        html5_basic = '<!DOCTYPE html>\n<html lang="en">\n<head>\n' .. indent .. '  <meta charset="UTF-8">\n' .. indent .. '  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n' .. indent .. '  <title></title>\n</head>\n<body>\n' .. indent .. '  \n</body>\n</html>',
        navigation = '<nav>\n' .. indent .. '  <ul>\n' .. indent .. '    <li><a href=""></a></li>\n' .. indent .. '  </ul>\n</nav>',
        article = '<article>\n' .. indent .. '  <header>\n' .. indent .. '    <h1></h1>\n' .. indent .. '  </header>\n' .. indent .. '  <p></p>\n</article>',
        aside = '<aside>\n' .. indent .. '  <h2></h2>\n' .. indent .. '  <p></p>\n</aside>',
        footer_info = '<footer>\n' .. indent .. '  <p>&copy; 2025 </p>\n</footer>',
        form_contact = '<form action="" method="post">\n' .. indent .. '  <label for="">:</label>\n' .. indent .. '  <input type="text" id="" name="" required>\n' .. indent .. '  <button type="submit">Submit</button>\n</form>',
        table_data = '<table>\n' .. indent .. '  <thead>\n' .. indent .. '    <tr>\n' .. indent .. '      <th></th>\n' .. indent .. '    </tr>\n' .. indent .. '  </thead>\n' .. indent .. '  <tbody>\n' .. indent .. '    <tr>\n' .. indent .. '      <td></td>\n' .. indent .. '    </tr>\n' .. indent .. '  </tbody>\n</table>',
        media_figure = '<figure>\n' .. indent .. '  <img src="" alt="">\n' .. indent .. '  <figcaption></figcaption>\n</figure>'
      }
      vim.api.nvim_put(vim.split(templates[choice], '\n'), 'l', true, true)
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert HTML5 structure' })

-- Comment toggle
vim.keymap.set('n', '<leader>/', function()
  local line = vim.api.nvim_get_current_line()
  if line:match('<!--.*-->') then
    -- Uncomment
    local new_line = line:gsub('<!--%s*(.-)%s*-->', '%1')
    vim.api.nvim_set_current_line(new_line)
  else
    -- Comment
    local trimmed = vim.trim(line)
    if trimmed ~= '' then
      local indent = line:match('^%s*')
      vim.api.nvim_set_current_line(indent .. '<!-- ' .. trimmed .. ' -->')
    end
  end
end, { buffer = true, desc = 'Toggle HTML comment' })

-- Navigation mappings
vim.keymap.set('n', ']]', '/<[a-zA-Z][^>]*><CR>',
  { buffer = true, desc = 'Next opening tag' })
vim.keymap.set('n', '[[', '?<[a-zA-Z][^>]*><CR>',
  { buffer = true, desc = 'Previous opening tag' })
vim.keymap.set('n', '}', '/<\/[a-zA-Z][^>]*><CR>',
  { buffer = true, desc = 'Next closing tag' })
vim.keymap.set('n', '{', '?<\/[a-zA-Z][^>]*><CR>',
  { buffer = true, desc = 'Previous closing tag' })
-- }}}1

-- HTML Validation and Tools {{{1
local function validate_html()
  local current_file = vim.fn.expand('%:p')

  if vim.fn.executable('tidy') == 1 then
    local result = vim.fn.system('tidy -e -q ' .. current_file .. ' 2>&1')
    if vim.v.shell_error == 0 then
      vim.notify('✓ HTML is valid', vim.log.levels.INFO)
    else
      vim.notify('HTML validation issues:\n' .. result, vim.log.levels.WARN)
    end
  else
    vim.notify('HTML Tidy not available. Install with: apt install tidy', vim.log.levels.ERROR)
  end
end

local function format_html()
  if vim.fn.executable('tidy') == 1 then
    local result = vim.fn.system('tidy -i -w 120 --drop-empty-elements no --tidy-mark no',
      table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'))

    if vim.v.shell_error <= 1 then -- tidy returns 1 for warnings, which is ok
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(result, '\n'))
      vim.notify('Formatted with HTML Tidy', vim.log.levels.INFO)
    else
      vim.notify('Failed to format HTML', vim.log.levels.ERROR)
    end
  else
    vim.notify('HTML Tidy not available', vim.log.levels.ERROR)
  end
end

local function check_accessibility()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, '\n')
  local issues = {}

  -- Check for missing alt attributes on images
  for line_num, line in ipairs(lines) do
    if line:match('<img[^>]*>') and not line:match('alt=') then
      table.insert(issues, string.format('Line %d: <img> missing alt attribute', line_num))
    end
  end

  -- Check for missing labels on form inputs
  for line_num, line in ipairs(lines) do
    if line:match('<input[^>]*>') and not line:match('aria%-label=') then
      local id_match = line:match('id="([^"]*)"')
      if id_match then
        local has_label = false
        for _, check_line in ipairs(lines) do
          if check_line:match('for="' .. id_match .. '"') then
            has_label = true
            break
          end
        end
        if not has_label then
          table.insert(issues, string.format('Line %d: <input> missing associated <label>', line_num))
        end
      else
        table.insert(issues, string.format('Line %d: <input> missing id or aria-label', line_num))
      end
    end
  end

  -- Check for heading hierarchy
  local last_heading_level = 0
  for line_num, line in ipairs(lines) do
    local heading = line:match('<h([1-6])[^>]*>')
    if heading then
      local level = tonumber(heading)
      if level > last_heading_level + 1 then
        table.insert(issues, string.format('Line %d: Heading level jumps from h%d to h%d', line_num, last_heading_level, level))
      end
      last_heading_level = level
    end
  end

  -- Check for missing lang attribute
  if not content:match('<html[^>]*lang=') then
    table.insert(issues, 'Missing lang attribute on <html> element')
  end

  -- Check for missing meta charset
  if not content:match('<meta[^>]*charset=') then
    table.insert(issues, 'Missing meta charset declaration')
  end

  if #issues == 0 then
    vim.notify('✓ No obvious accessibility issues found', vim.log.levels.INFO)
  else
    vim.notify('Accessibility suggestions:\n' .. table.concat(issues, '\n'), vim.log.levels.WARN)
  end
end

local function check_html_best_practices()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local issues = {}

  for i, line in ipairs(lines) do
    -- Check for inline styles
    if line:match('style=') then
      table.insert(issues, string.format('Line %d: Consider using CSS classes instead of inline styles', i))
    end

    -- Check for deprecated tags
    local deprecated_tags = { 'font', 'center', 'b', 'i', 'u', 'strike', 'big', 'small' }
    for _, tag in ipairs(deprecated_tags) do
      if line:match('<' .. tag .. '[^>]*>') then
        table.insert(issues, string.format('Line %d: <%s> tag is deprecated', i, tag))
      end
    end

    -- Check for missing DOCTYPE
    if i == 1 and not line:match('<!DOCTYPE') then
      table.insert(issues, 'Line 1: Missing DOCTYPE declaration')
    end

    -- Check for unclosed tags (basic check)
    local self_closing = { 'img', 'br', 'hr', 'input', 'meta', 'link', 'area', 'base', 'col', 'embed', 'source', 'track', 'wbr' }
    for tag in line:gmatch('<([a-zA-Z]+)[^>]*>') do
      if not vim.tbl_contains(self_closing, tag:lower()) then
        local close_tag = '</' .. tag .. '>'
        if not line:match(close_tag) then
          -- This is a basic check - could be improved
        end
      end
    end
  end

  if #issues == 0 then
    vim.notify('✓ No obvious best practice issues found', vim.log.levels.INFO)
  else
    vim.notify('Best practice suggestions:\n' .. table.concat(issues, '\n'), vim.log.levels.WARN)
  end
end

local function open_in_browser()
  local current_file = vim.fn.expand('%:p')
  if vim.fn.has('macunix') == 1 then
    vim.fn.system('open ' .. current_file)
  elseif vim.fn.has('unix') == 1 then
    vim.fn.system('xdg-open ' .. current_file)
  elseif vim.fn.has('win32') == 1 then
    vim.fn.system('start ' .. current_file)
  else
    vim.notify('Unable to open browser on this system', vim.log.levels.ERROR)
  end
end

-- HTML tool mappings
vim.keymap.set('n', '<leader>hv', validate_html, { buffer = true, desc = 'Validate HTML' })
vim.keymap.set('n', '<leader>hf', format_html, { buffer = true, desc = 'Format HTML' })
vim.keymap.set('n', '<leader>ha', check_accessibility, { buffer = true, desc = 'Check accessibility' })
vim.keymap.set('n', '<leader>hc', check_html_best_practices, { buffer = true, desc = 'Check best practices' })
vim.keymap.set('n', '<leader>ho', open_in_browser, { buffer = true, desc = 'Open in browser' })
-- }}}1

-- HTML Snippets {{{1
-- Set up snippet integration if LuaSnip is available
local ok, luasnip = pcall(require, 'luasnip')
if ok then
  luasnip.add_snippets('html', {
    luasnip.snippet('html5', {
      luasnip.text_node({'<!DOCTYPE html>', '<html lang="en">', '<head>', '    <meta charset="UTF-8">', '    <meta name="viewport" content="width=device-width, initial-scale=1.0">', '    <title>'}),
      luasnip.insert_node(1, 'Document'),
      luasnip.text_node({'</title>', '</head>', '<body>', '    '}),
      luasnip.insert_node(0),
      luasnip.text_node({'', '</body>', '</html>'}),
    }),

    luasnip.snippet('link', {
      luasnip.text_node('<a href="'),
      luasnip.insert_node(1, '#'),
      luasnip.text_node('">'),
      luasnip.insert_node(2, 'Link Text'),
      luasnip.text_node('</a>'),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('img', {
      luasnip.text_node('<img src="'),
      luasnip.insert_node(1, 'image.jpg'),
      luasnip.text_node('" alt="'),
      luasnip.insert_node(2, 'Description'),
      luasnip.text_node('">'),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('form', {
      luasnip.text_node('<form action="'),
      luasnip.insert_node(1, '#'),
      luasnip.text_node('" method="'),
      luasnip.choice_node(2, {
        luasnip.text_node('post'),
        luasnip.text_node('get'),
      }),
      luasnip.text_node({'">'}),
      luasnip.text_node({'', '    '}),
      luasnip.insert_node(3),
      luasnip.text_node({'', '</form>'}),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('table', {
      luasnip.text_node({'<table>', '    <thead>', '        <tr>', '            <th>'}),
      luasnip.insert_node(1, 'Header'),
      luasnip.text_node({'</th>', '        </tr>', '    </thead>', '    <tbody>', '        <tr>', '            <td>'}),
      luasnip.insert_node(2, 'Data'),
      luasnip.text_node({'</td>', '        </tr>', '    </tbody>', '</table>'}),
      luasnip.insert_node(0),
    }),
  })
end
-- }}}1

-- HTML Auto Commands {{{1
-- Auto-close tags
vim.api.nvim_create_autocmd('InsertCharPre', {
  buffer = 0,
  callback = function()
    local char = vim.v.char
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    -- Auto-close tags when typing >
    if char == '>' then
      local before_cursor = line:sub(1, col)
      local tag_match = before_cursor:match('<([a-zA-Z][a-zA-Z0-9]*)[^>]*$')

      if tag_match then
        local self_closing = { 'img', 'br', 'hr', 'input', 'meta', 'link', 'area', 'base', 'col', 'embed', 'source', 'track', 'wbr' }
        if not vim.tbl_contains(self_closing, tag_match:lower()) then
          vim.schedule(function()
            vim.api.nvim_feedkeys('</' .. tag_match .. '>', 'n', true)
            vim.api.nvim_feedkeys(string.rep('\b', #tag_match + 3), 'n', true)
          end)
        end
      end
    end
  end,
  desc = 'Auto-close HTML tags'
})

-- Auto-indent after tag creation
vim.api.nvim_create_autocmd('InsertEnter', {
  buffer = 0,
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    -- Check if cursor is between opening and closing tags
    local before = line:sub(1, col)
    local after = line:sub(col + 1)

    if before:match('<[^>]*>$') and after:match('^</') then
      vim.schedule(function()
        vim.api.nvim_feedkeys('\n', 'n', true)
        vim.api.nvim_feedkeys(string.rep(' ', vim.fn.shiftwidth()), 'n', true)
      end)
    end
  end,
  desc = 'Auto-indent between tags'
})

-- Live preview setup (if browser-sync or similar is available)
vim.api.nvim_create_autocmd('BufWritePost', {
  buffer = 0,
  callback = function()
    -- This could trigger live reload if you have browser-sync set up
    -- vim.fn.system('browser-sync reload')
  end,
  desc = 'Trigger live reload on save'
})
-- }}}1

-- HTML Commands {{{1
vim.api.nvim_create_user_command('HtmlValidate', function()
  validate_html()
end, { desc = 'Validate HTML with tidy' })

vim.api.nvim_create_user_command('HtmlFormat', function()
  format_html()
end, { desc = 'Format HTML with tidy' })

vim.api.nvim_create_user_command('HtmlAccessibility', function()
  check_accessibility()
end, { desc = 'Check HTML accessibility' })

vim.api.nvim_create_user_command('HtmlOpen', function()
  open_in_browser()
end, { desc = 'Open HTML file in browser' })

vim.api.nvim_create_user_command('HtmlPreview', function()
  -- Start a simple HTTP server for local preview
  local current_dir = vim.fn.expand('%:p:h')
  vim.cmd('split')
  vim.cmd('terminal cd ' .. current_dir .. ' && python3 -m http.server 8000')
  vim.notify('Preview server started at http://localhost:8000', vim.log.levels.INFO)
end, { desc = 'Start local preview server' })
-- }}}1