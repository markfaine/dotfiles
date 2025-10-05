-- vim: foldmethod=marker foldlevel=1

--[[ Jinja2 Template Configuration {{{1
Enhanced editing experience for Jinja2 templates with smart mappings,
template validation, syntax highlighting, and productivity features.
}}}1 --]]

-- Jinja2 Settings {{{1
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true
vim.opt_local.smartindent = true

-- Jinja2-specific options
vim.opt_local.textwidth = 120
vim.opt_local.colorcolumn = '121'
vim.opt_local.wrap = false
vim.opt_local.foldmethod = 'marker'
vim.opt_local.foldlevel = 1

-- Show whitespace (important for templates)
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

-- Detect template context
local function detect_template_context()
  local filename = vim.fn.expand('%:t')
  local filepath = vim.fn.expand('%:p')

  if filename:match('%.html%.j2$') or filename:match('%.html%.jinja2?$') then
    vim.b.jinja_context = 'html'
  elseif filename:match('%.xml%.j2$') or filename:match('%.xml%.jinja2?$') then
    vim.b.jinja_context = 'xml'
  elseif filename:match('%.yml%.j2$') or filename:match('%.yaml%.j2$') then
    vim.b.jinja_context = 'yaml'
  elseif filename:match('%.json%.j2$') then
    vim.b.jinja_context = 'json'
  elseif filepath:match('/templates/') then
    vim.b.jinja_context = 'ansible'
  else
    vim.b.jinja_context = 'generic'
  end
end

detect_template_context()

-- Smart Jinja2 Mappings {{{1
-- Jinja2 expression insertion
vim.keymap.set('i', '<C-j>', function()
  return '{{ }}'
end, { buffer = true, expr = true, desc = 'Insert Jinja2 expression' })

-- Jinja2 statement insertion
vim.keymap.set('i', '<C-s>', function()
  return '{% %}'
end, { buffer = true, expr = true, desc = 'Insert Jinja2 statement' })

-- Jinja2 comment insertion
vim.keymap.set('i', '<C-c>', function()
  return '{# #}'
end, { buffer = true, expr = true, desc = 'Insert Jinja2 comment' })

-- Smart block creation
vim.keymap.set('i', '<C-b>', function()
  local blocks = {
    'if', 'for', 'block', 'macro', 'call', 'filter',
    'with', 'autoescape', 'raw', 'set'
  }

  vim.ui.select(blocks, {
    prompt = 'Select Jinja2 block:',
  }, function(choice)
    if choice then
      local indent = string.rep(' ', vim.fn.indent('.'))
      local templates = {
        ['if'] = '{% if %}\n' .. indent .. '\n' .. indent .. '{% endif %}',
        ['for'] = '{% for item in %}\n' .. indent .. '\n' .. indent .. '{% endfor %}',
        ['block'] = '{% block %}\n' .. indent .. '\n' .. indent .. '{% endblock %}',
        ['macro'] = '{% macro name() %}\n' .. indent .. '\n' .. indent .. '{% endmacro %}',
        ['call'] = '{% call %}\n' .. indent .. '\n' .. indent .. '{% endcall %}',
        ['filter'] = '{% filter %}\n' .. indent .. '\n' .. indent .. '{% endfilter %}',
        ['with'] = '{% with %}\n' .. indent .. '\n' .. indent .. '{% endwith %}',
        ['autoescape'] = '{% autoescape %}\n' .. indent .. '\n' .. indent .. '{% endautoescape %}',
        ['raw'] = '{% raw %}\n' .. indent .. '\n' .. indent .. '{% endraw %}',
        ['set'] = '{% set  = %}'
      }
      vim.api.nvim_put(vim.split(templates[choice], '\n'), 'l', true, true)
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert Jinja2 block' })

-- Quick filter insertion
vim.keymap.set('i', '<C-f>', function()
  local filters = {
    'default', 'length', 'upper', 'lower', 'title', 'trim',
    'replace', 'join', 'split', 'first', 'last', 'sort',
    'reverse', 'unique', 'list', 'string', 'int', 'float',
    'abs', 'round', 'tojson', 'fromjson', 'safe', 'escape'
  }

  vim.ui.select(filters, {
    prompt = 'Select Jinja2 filter:',
  }, function(choice)
    if choice then
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      vim.api.nvim_set_current_line(line:sub(1, col) .. '|' .. choice .. line:sub(col + 1))
      vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + #choice + 1 })
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert Jinja2 filter' })

-- Context-aware variable insertion
vim.keymap.set('i', '<C-v>', function()
  local context_vars = {
    ansible = {
      'ansible_facts', 'hostvars', 'group_names', 'groups',
      'inventory_hostname', 'play_hosts', 'ansible_version',
      'ansible_user', 'ansible_host', 'ansible_port'
    },
    generic = {
      'item', 'loop', 'request', 'session', 'config',
      'url_for', 'get_flashed_messages', 'moment'
    }
  }

  local vars = context_vars[vim.b.jinja_context] or context_vars.generic

  vim.ui.select(vars, {
    prompt = 'Select variable:',
  }, function(choice)
    if choice then
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      vim.api.nvim_set_current_line(line:sub(1, col) .. choice .. line:sub(col + 1))
      vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + #choice })
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert context variable' })

-- Navigation mappings
vim.keymap.set('n', ']]', '/{% \\(block\\|macro\\|if\\|for\\)<CR>',
  { buffer = true, desc = 'Next Jinja2 block' })
vim.keymap.set('n', '[[', '?{% \\(block\\|macro\\|if\\|for\\)<CR>',
  { buffer = true, desc = 'Previous Jinja2 block' })
vim.keymap.set('n', '}', '/{% end<CR>',
  { buffer = true, desc = 'Next end tag' })
vim.keymap.set('n', '{', '?{% end<CR>',
  { buffer = true, desc = 'Previous end tag' })
-- }}}1

-- Jinja2 Validation and Tools {{{1
local function validate_jinja2()
  local current_file = vim.fn.expand('%:p')

  -- Basic syntax validation using Python
  local python_check = [[
import sys
from jinja2 import Environment, FileSystemLoader, TemplateSyntaxError
import os

try:
    env = Environment(loader=FileSystemLoader(os.path.dirname(']] .. current_file .. [[')))
    template = env.get_template(os.path.basename(']] .. current_file .. [['))
    print("✓ Jinja2 syntax is valid")
    sys.exit(0)
except TemplateSyntaxError as e:
    print(f"✗ Jinja2 syntax error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"✗ Error: {e}")
    sys.exit(1)
]]

  local temp_file = vim.fn.tempname() .. '.py'
  vim.fn.writefile(vim.split(python_check, '\n'), temp_file)
  local result = vim.fn.system('python3 ' .. temp_file)
  vim.fn.delete(temp_file)

  if vim.v.shell_error == 0 then
    vim.notify(result, vim.log.levels.INFO)
  else
    vim.notify(result, vim.log.levels.ERROR)
  end
end

local function check_jinja2_best_practices()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local issues = {}
  local block_stack = {}

  for i, line in ipairs(lines) do
    -- Check for unmatched blocks
    for block_start in line:gmatch('{% (%w+)') do
      if block_start ~= 'endif' and block_start ~= 'endfor' and block_start ~= 'endblock' then
        table.insert(block_stack, { block_start, i })
      end
    end

    for block_end in line:gmatch('{% end(%w+)') do
      if #block_stack > 0 then
        local last_block = table.remove(block_stack)
        if last_block[1] ~= block_end then
          table.insert(issues, string.format('Line %d: Mismatched block end', i))
        end
      else
        table.insert(issues, string.format('Line %d: Unexpected end block', i))
      end
    end

    -- Check for missing spaces in expressions
    if line:match('{{[^%s]') or line:match('[^%s]}}') then
      table.insert(issues, string.format('Line %d: Missing spaces around {{ }}', i))
    end

    if line:match('{%[^%s]') or line:match('[^%s]%}') then
      table.insert(issues, string.format('Line %d: Missing spaces around {% %}', i))
    end

    -- Check for potentially unsafe variables
    if line:match('{{.*|safe') then
      table.insert(issues, string.format('Line %d: Review |safe filter usage for security', i))
    end

    -- Check for complex expressions that might be better as filters
    if line:match('{{.*%..*%..*}}') then
      table.insert(issues, string.format('Line %d: Consider using custom filter for complex expression', i))
    end
  end

  -- Check for unmatched opening blocks
  for _, block in ipairs(block_stack) do
    table.insert(issues, string.format('Line %d: Unmatched %s block', block[2], block[1]))
  end

  if #issues == 0 then
    vim.notify('✓ No obvious best practice issues found', vim.log.levels.INFO)
  else
    vim.notify('Best practice suggestions:\n' .. table.concat(issues, '\n'), vim.log.levels.WARN)
  end
end

local function render_template()
  local current_file = vim.fn.expand('%:p')

  vim.ui.input({ prompt = 'Context file (JSON/YAML): ' }, function(context_file)
    if context_file and context_file ~= '' then
      local python_render = [[
import sys
import json
import yaml
from jinja2 import Environment, FileSystemLoader
import os

try:
    # Load context
    with open(']] .. context_file .. [[', 'r') as f:
        if ']] .. context_file .. [['.endswith('.json'):
            context = json.load(f)
        else:
            context = yaml.safe_load(f)

    # Render template
    env = Environment(loader=FileSystemLoader(os.path.dirname(']] .. current_file .. [[')))
    template = env.get_template(os.path.basename(']] .. current_file .. [['))
    result = template.render(context)
    print(result)

except Exception as e:
    print(f"Error rendering template: {e}")
    sys.exit(1)
]]

      local temp_file = vim.fn.tempname() .. '.py'
      vim.fn.writefile(vim.split(python_render, '\n'), temp_file)
      local result = vim.fn.system('python3 ' .. temp_file)
      vim.fn.delete(temp_file)

      if vim.v.shell_error == 0 then
        vim.cmd('vnew')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(result, '\n'))
        vim.bo.filetype = 'text'
      else
        vim.notify(result, vim.log.levels.ERROR)
      end
    end
  end)
end

local function render_jinja2()
  local run = require('core.extras.utility').run
  -- assemble temp python script as in your existing implementation
  local python_render = [[
import sys, jinja2
from jinja2 import Template
text = sys.stdin.read()
print(Template(text).render())
]]
  local temp_py = vim.fn.tempname() .. '.py'
  vim.fn.writefile(vim.split(python_render, '\n'), temp_py)

  local buf_text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')

  -- run python3, feed stdin via file to keep it simple (use a temp file)
  local temp_in = vim.fn.tempname() .. '.jinja'
  vim.fn.writefile(vim.split(buf_text, '\n'), temp_in)

  run({ 'python3', temp_py },
    function(stdout)
      vim.cmd('vnew')
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(stdout, '\n'))
      vim.bo.filetype = 'text'
      vim.fn.delete(temp_py)
      vim.fn.delete(temp_in)
    end,
    function(err)
      vim.notify(err, vim.log.levels.ERROR)
      vim.fn.delete(temp_py)
      vim.fn.delete(temp_in)
    end)
end

local function format_jinja2()
  -- Basic formatting - add spaces around expressions if missing
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local modified = false

  for i, line in ipairs(lines) do
    local new_line = line

    -- Fix spacing around expressions
    new_line = new_line:gsub('{{([^%s])', '{{ %1')
    new_line = new_line:gsub('([^%s]}})', '%1 }}')
    new_line = new_line:gsub('{%([^%s])', '{% %1')
    new_line = new_line:gsub('([^%s]%})', '%1 %}')

    if new_line ~= line then
      lines[i] = new_line
      modified = true
    end
  end

  if modified then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.notify('Formatted Jinja2 expressions', vim.log.levels.INFO)
  else
    vim.notify('No formatting changes needed', vim.log.levels.INFO)
  end
end

-- Jinja2 tool mappings
vim.keymap.set('n', '<leader>jv', validate_jinja2, { buffer = true, desc = 'Validate Jinja2 syntax' })
vim.keymap.set('n', '<leader>jc', check_jinja2_best_practices, { buffer = true, desc = 'Check best practices' })
vim.keymap.set('n', '<leader>jr', render_template, { buffer = true, desc = 'Render template' })
vim.keymap.set('n', '<leader>jf', format_jinja2, { buffer = true, desc = 'Format Jinja2' })
-- }}}1

-- Jinja2 Snippets {{{1
-- Set up snippet integration if LuaSnip is available
local ok, luasnip = pcall(require, 'luasnip')
if ok then
  luasnip.add_snippets('jinja', {
    luasnip.snippet('var', {
      luasnip.text_node('{{ '),
      luasnip.insert_node(1, 'variable'),
      luasnip.text_node(' }}'),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('if', {
      luasnip.text_node('{% if '),
      luasnip.insert_node(1, 'condition'),
      luasnip.text_node(' %}'),
      luasnip.text_node({'', '    '}),
      luasnip.insert_node(2),
      luasnip.text_node({'', '{% endif %}')),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('for', {
      luasnip.text_node('{% for '),
      luasnip.insert_node(1, 'item'),
      luasnip.text_node(' in '),
      luasnip.insert_node(2, 'items'),
      luasnip.text_node(' %}'),
      luasnip.text_node({'', '    '}),
      luasnip.insert_node(3),
      luasnip.text_node({'', '{% endfor %}')),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('block', {
      luasnip.text_node('{% block '),
      luasnip.insert_node(1, 'name'),
      luasnip.text_node(' %}'),
      luasnip.text_node({'', '    '}),
      luasnip.insert_node(2),
      luasnip.text_node({'', '{% endblock '}),
      luasnip.rep(1),
      luasnip.text_node(' %}'),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('macro', {
      luasnip.text_node('{% macro '),
      luasnip.insert_node(1, 'name'),
      luasnip.text_node('('),
      luasnip.insert_node(2, 'args'),
      luasnip.text_node(') %}'),
      luasnip.text_node({'', '    '}),
      luasnip.insert_node(3),
      luasnip.text_node({'', '{% endmacro %}')),
      luasnip.insert_node(0),
    }),
  })
end
-- }}}1

-- Jinja2 Auto Commands {{{1
-- Auto-complete Jinja2 expressions
vim.api.nvim_create_autocmd('InsertCharPre', {
  buffer = 0,
  callback = function()
    local char = vim.v.char
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    -- Auto-complete {{ }}
    if char == '{' and col > 0 and line:sub(col, col) == '{' then
      vim.schedule(function()
        vim.api.nvim_feedkeys('  }}', 'n', true)
        vim.api.nvim_feedkeys(string.rep('\b', 3), 'n', true)
      end)
    end

    -- Auto-complete {% %}
    if char == '%' and col > 0 and line:sub(col, col) == '{' then
      vim.schedule(function()
        vim.api.nvim_feedkeys('  %}', 'n', true)
        vim.api.nvim_feedkeys(string.rep('\b', 3), 'n', true)
      end)
    end

    -- Auto-complete {# #}
    if char == '#' and col > 0 and line:sub(col, col) == '{' then
      vim.schedule(function()
        vim.api.nvim_feedkeys('  #}', 'n', true)
        vim.api.nvim_feedkeys(string.rep('\b', 3), 'n', true)
      end)
    end
  end,
  desc = 'Auto-complete Jinja2 expressions'
})

-- Highlight unmatched blocks
vim.api.nvim_create_autocmd('BufEnter', {
  buffer = 0,
  callback = function()
    vim.fn.matchadd('Error', '{%.*without.*end.*%}')
  end,
  desc = 'Highlight potential unmatched Jinja2 blocks'
})

-- Set appropriate file type based on extension
vim.api.nvim_create_autocmd('BufRead', {
  buffer = 0,
  callback = function()
    local filename = vim.fn.expand('%:t')
    if filename:match('%.html%.j2$') or filename:match('%.html%.jinja2?$') then
      vim.bo.filetype = 'jinja.html'
    elseif filename:match('%.xml%.j2$') then
      vim.bo.filetype = 'jinja.xml'
    elseif filename:match('%.yml%.j2$') or filename:match('%.yaml%.j2$') then
      vim.bo.filetype = 'jinja.yaml'
    end
  end,
  desc = 'Set composite filetype for Jinja2 templates'
})
-- }}}1

-- Jinja2 Commands {{{1
vim.api.nvim_create_user_command('JinjaValidate', function()
  validate_jinja2()
end, { desc = 'Validate Jinja2 template syntax' })

vim.api.nvim_create_user_command('JinjaRender', function()
  render_template()
end, { desc = 'Render Jinja2 template with context' })

vim.api.nvim_create_user_command('JinjaFormat', function()
  format_jinja2()
end, { desc = 'Format Jinja2 expressions' })

vim.api.nvim_create_user_command('JinjaCheck', function()
  check_jinja2_best_practices()
end, { desc = 'Check Jinja2 best practices' })
-- }}}1