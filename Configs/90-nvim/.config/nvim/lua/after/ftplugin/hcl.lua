-- vim: foldmethod=marker foldlevel=1

--[[ HCL Configuration {{{1
Enhanced editing experience for HCL (HashiCorp Configuration Language) files
including Terraform, Packer, Vault, and other HashiCorp tools with validation,
formatting, smart mappings, and productivity features.
}}}1 --]]

-- HCL Settings {{{1
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true
vim.opt_local.smartindent = true

-- HCL-specific options
vim.opt_local.textwidth = 120
vim.opt_local.colorcolumn = '121'
vim.opt_local.wrap = false
vim.opt_local.foldmethod = 'indent'
vim.opt_local.foldlevel = 1

-- Show whitespace (important for HCL)
vim.opt_local.list = true
vim.opt_local.listchars = {
  tab = '»·',
  trail = '·',
  extends = '❯',
  precedes = '❮',
  nbsp = '⦸',
}

-- Enable spell checking for comments and strings
vim.opt_local.spell = true
vim.opt_local.spelllang = 'en_us'

-- Detect HCL context
local function detect_hcl_context()
  local filename = vim.fn.expand('%:t')
  local filepath = vim.fn.expand('%:p')

  if filename:match('%.tf$') or filename:match('%.tfvars$') then
    vim.b.hcl_context = 'terraform'
  elseif filename:match('%.pkr%.hcl$') or filepath:match('/packer/') then
    vim.b.hcl_context = 'packer'
  elseif filename:match('%.vault%.hcl$') or filepath:match('/vault/') then
    vim.b.hcl_context = 'vault'
  elseif filename:match('%.consul%.hcl$') or filepath:match('/consul/') then
    vim.b.hcl_context = 'consul'
  elseif filename:match('%.nomad$') or filepath:match('/nomad/') then
    vim.b.hcl_context = 'nomad'
  else
    vim.b.hcl_context = 'generic'
  end
end

detect_hcl_context()
-- }}}1

-- Smart HCL Mappings {{{1
-- Quick block creation
vim.keymap.set('i', '<C-b>', function()
  local context = vim.b.hcl_context or 'generic'
  local blocks = {}

  if context == 'terraform' then
    blocks = {
      'resource', 'data', 'variable', 'output', 'locals',
      'module', 'provider', 'terraform', 'moved', 'import'
    }
  elseif context == 'packer' then
    blocks = {
      'source', 'build', 'variable', 'locals', 'packer'
    }
  elseif context == 'vault' then
    blocks = {
      'storage', 'listener', 'ui', 'api_addr', 'cluster_addr'
    }
  else
    blocks = {
      'block', 'variable', 'locals'
    }
  end

  vim.ui.select(blocks, {
    prompt = 'Select HCL block type:',
  }, function(choice)
    if choice then
      local indent = string.rep(' ', vim.fn.indent('.'))
      local template

      if choice == 'resource' then
        template = choice .. ' "" "" {\n' .. indent .. '  \n' .. indent .. '}'
      elseif choice == 'data' then
        template = choice .. ' "" "" {\n' .. indent .. '  \n' .. indent .. '}'
      elseif choice == 'variable' or choice == 'output' then
        template = choice .. ' "" {\n' .. indent .. '  \n' .. indent .. '}'
      else
        template = choice .. ' {\n' .. indent .. '  \n' .. indent .. '}'
      end

      vim.api.nvim_put(vim.split(template, '\n'), 'l', true, true)
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert HCL block' })

-- Quick attribute insertion
vim.keymap.set('i', '<C-a>', function()
  local context = vim.b.hcl_context or 'generic'
  local attributes = {}

  if context == 'terraform' then
    attributes = {
      'count = ', 'for_each = ', 'depends_on = []',
      'lifecycle {}', 'provider = ', 'tags = {}',
      'name = ""', 'type = ""', 'default = ',
      'description = ""', 'sensitive = false'
    }
  elseif context == 'packer' then
    attributes = {
      'type = ""', 'name = ""', 'source = ""',
      'boot_command = []', 'ssh_username = ""'
    }
  else
    attributes = {
      'name = ""', 'type = ""', 'value = ""'
    }
  end

  vim.ui.select(attributes, {
    prompt = 'Select HCL attribute:',
  }, function(choice)
    if choice then
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      vim.api.nvim_set_current_line(line:sub(1, col) .. choice .. line:sub(col + 1))
      vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + #choice })
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert HCL attribute' })

-- Function and expression helpers
vim.keymap.set('i', '<C-f>', function()
  local functions = {
    'length()', 'keys()', 'values()', 'lookup()', 'merge()',
    'concat()', 'join()', 'split()', 'replace()', 'trim()',
    'upper()', 'lower()', 'title()', 'substr()', 'format()',
    'tostring()', 'tonumber()', 'tobool()', 'tolist()', 'toset()',
    'file()', 'filebase64()', 'templatefile()', 'base64encode()',
    'jsonencode()', 'jsondecode()', 'yamlencode()', 'yamldecode()'
  }

  vim.ui.select(functions, {
    prompt = 'Select HCL function:',
  }, function(choice)
    if choice then
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      vim.api.nvim_set_current_line(line:sub(1, col) .. choice .. line:sub(col + 1))
      -- Position cursor inside parentheses
      vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + #choice - 1 })
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert HCL function' })

-- Variable reference helper
vim.keymap.set('i', '<C-v>', function()
  local references = {
    'var.', 'local.', 'data.', 'module.', 'resource.',
    'path.module', 'path.root', 'path.cwd',
    'terraform.workspace', 'each.key', 'each.value',
    'count.index', 'self.'
  }

  vim.ui.select(references, {
    prompt = 'Select variable reference:',
  }, function(choice)
    if choice then
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      vim.api.nvim_set_current_line(line:sub(1, col) .. choice .. line:sub(col + 1))
      vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + #choice })
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert variable reference' })

-- Navigation mappings
vim.keymap.set('n', ']]', '/^\\s*\\(resource\\|data\\|variable\\|output\\|module\\)<CR>',
  { buffer = true, desc = 'Next HCL block' })
vim.keymap.set('n', '[[', '?^\\s*\\(resource\\|data\\|variable\\|output\\|module\\)<CR>',
  { buffer = true, desc = 'Previous HCL block' })
vim.keymap.set('n', '}', '/^\\s*}<CR>',
  { buffer = true, desc = 'Next closing brace' })
vim.keymap.set('n', '{', '?^\\s*{<CR>',
  { buffer = true, desc = 'Previous opening brace' })
-- }}}1

-- HCL Validation and Tools {{{1
local function validate_hcl()
  local current_file = vim.fn.expand('%:p')
  local context = vim.b.hcl_context or 'generic'

  if context == 'terraform' then
    if vim.fn.executable('terraform') == 1 then
      local result = vim.fn.system('cd ' .. vim.fn.expand('%:p:h') .. ' && terraform validate')
      if vim.v.shell_error == 0 then
        vim.notify('✓ Terraform configuration is valid', vim.log.levels.INFO)
      else
        vim.notify('Terraform validation errors:\n' .. result, vim.log.levels.ERROR)
      end
    else
      vim.notify('Terraform not available', vim.log.levels.ERROR)
    end
  else
    -- Generic HCL validation
    if vim.fn.executable('hcl2json') == 1 then
      local result = vim.fn.system('hcl2json < ' .. current_file .. ' > /dev/null')
      if vim.v.shell_error == 0 then
        vim.notify('✓ HCL syntax is valid', vim.log.levels.INFO)
      else
        vim.notify('HCL syntax errors found', vim.log.levels.ERROR)
      end
    else
      vim.notify('hcl2json not available for validation', vim.log.levels.WARN)
    end
  end
end

local function format_hcl()
  local run = require('core.extras.utility').run
  local context = vim.b.hcl_context or 'generic'
  local current_file = vim.fn.expand('%:p')

  if context == 'terraform' then
    if vim.fn.executable('terraform') == 1 then
      run({ 'terraform', 'fmt', current_file },
        function()
          vim.cmd('edit!')
          vim.notify('Formatted with terraform fmt', vim.log.levels.INFO)
        end,
        function(err) vim.notify('Failed to format with terraform fmt:\n' .. err, vim.log.levels.ERROR) end)
    else
      vim.notify('Terraform not available', vim.log.levels.ERROR)
    end
  else
    -- keep existing generic HCL formatting (stdin-based) unmodified
    -- to avoid changing semantics if hclfmt only reads from stdin in your setup
    if vim.fn.executable('hclfmt') == 1 then
      local formatted = vim.fn.system('hclfmt', table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'))
      if vim.v.shell_error == 0 then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(formatted, '\n'))
        vim.notify('Formatted with hclfmt', vim.log.levels.INFO)
      else
        vim.notify('Failed to format with hclfmt', vim.log.levels.ERROR)
      end
    else
      vim.notify('hclfmt not available', vim.log.levels.WARN)
    end
  end
end

local function check_hcl_best_practices()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local context = vim.b.hcl_context or 'generic'
  local issues = {}

  for i, line in ipairs(lines) do
    -- Check for hardcoded values
    if line:match('ami%-[a-f0-9]+') then
      table.insert(issues, string.format('Line %d: Consider using data source for AMI', i))
    end

    -- Check for missing descriptions
    if context == 'terraform' then
      if line:match('^%s*variable%s') then
        local next_lines = table.concat(vim.list_slice(lines, i, math.min(#lines, i + 10)), '\n')
        if not next_lines:match('description%s*=') then
          table.insert(issues, string.format('Line %d: Variable missing description', i))
        end
      end

      if line:match('^%s*output%s') then
        local next_lines = table.concat(vim.list_slice(lines, i, math.min(#lines, i + 10)), '\n')
        if not next_lines:match('description%s*=') then
          table.insert(issues, string.format('Line %d: Output missing description', i))
        end
      end
    end

    -- Check for missing tags
    if context == 'terraform' and line:match('resource%s+"aws_') then
      local block_end = i
      for j = i + 1, #lines do
        if lines[j]:match('^}') then
          block_end = j
          break
        end
      end

      local block_content = table.concat(vim.list_slice(lines, i, block_end), '\n')
      if not block_content:match('tags%s*=') then
        table.insert(issues, string.format('Line %d: AWS resource missing tags', i))
      end
    end

    -- Check for sensitive values in plain text
    if line:match('password%s*=') or line:match('secret%s*=') then
      if not line:match('var%.') and not line:match('sensitive') then
        table.insert(issues, string.format('Line %d: Sensitive value should use variable', i))
      end
    end
  end

  if #issues == 0 then
    vim.notify('✓ No obvious best practice issues found', vim.log.levels.INFO)
  else
    vim.notify('Best practice suggestions:\n' .. table.concat(issues, '\n'), vim.log.levels.WARN)
  end
end

local function terraform_plan()
  if vim.b.hcl_context == 'terraform' then
    if vim.fn.executable('terraform') == 1 then
      vim.cmd('split')
      vim.cmd('terminal cd ' .. vim.fn.expand('%:p:h') .. ' && terraform plan')
    else
      vim.notify('Terraform not available', vim.log.levels.ERROR)
    end
  else
    vim.notify('Not a Terraform file', vim.log.levels.WARN)
  end
end

local function terraform_apply()
  if vim.b.hcl_context == 'terraform' then
    if vim.fn.executable('terraform') == 1 then
      vim.ui.input({ prompt = 'Apply changes? Type "yes" to confirm: ' }, function(input)
        if input == 'yes' then
          vim.cmd('split')
          vim.cmd('terminal cd ' .. vim.fn.expand('%:p:h') .. ' && terraform apply')
        end
      end)
    else
      vim.notify('Terraform not available', vim.log.levels.ERROR)
    end
  else
    vim.notify('Not a Terraform file', vim.log.levels.WARN)
  end
end

-- HCL tool mappings
vim.keymap.set('n', '<leader>hv', validate_hcl, { buffer = true, desc = 'Validate HCL' })
vim.keymap.set('n', '<leader>hf', format_hcl, { buffer = true, desc = 'Format HCL' })
vim.keymap.set('n', '<leader>hc', check_hcl_best_practices, { buffer = true, desc = 'Check best practices' })
vim.keymap.set('n', '<leader>hp', terraform_plan, { buffer = true, desc = 'Terraform plan' })
vim.keymap.set('n', '<leader>ha', terraform_apply, { buffer = true, desc = 'Terraform apply' })
-- }}}1

-- HCL Snippets {{{1
-- Set up snippet integration if LuaSnip is available
local ok, luasnip = pcall(require, 'luasnip')
if ok then
  luasnip.add_snippets('hcl', {
    luasnip.snippet('resource', {
      luasnip.text_node('resource "'),
      luasnip.insert_node(1, 'type'),
      luasnip.text_node('" "'),
      luasnip.insert_node(2, 'name'),
      luasnip.text_node({'" {', '  '}),
      luasnip.insert_node(0),
      luasnip.text_node({'', '}'}),
    }),

    luasnip.snippet('data', {
      luasnip.text_node('data "'),
      luasnip.insert_node(1, 'type'),
      luasnip.text_node('" "'),
      luasnip.insert_node(2, 'name'),
      luasnip.text_node({'" {', '  '}),
      luasnip.insert_node(0),
      luasnip.text_node({'', '}'}),
    }),

    luasnip.snippet('variable', {
      luasnip.text_node('variable "'),
      luasnip.insert_node(1, 'name'),
      luasnip.text_node({'" {', '  description = "'}),
      luasnip.insert_node(2, 'Description'),
      luasnip.text_node({'"', '  type        = '}),
      luasnip.choice_node(3, {
        luasnip.text_node('string'),
        luasnip.text_node('number'),
        luasnip.text_node('bool'),
        luasnip.text_node('list(string)'),
        luasnip.text_node('map(string)'),
      }),
      luasnip.text_node({'', '  default     = '}),
      luasnip.insert_node(4, 'null'),
      luasnip.text_node({'', '}'}),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('output', {
      luasnip.text_node('output "'),
      luasnip.insert_node(1, 'name'),
      luasnip.text_node({'" {', '  description = "'}),
      luasnip.insert_node(2, 'Description'),
      luasnip.text_node({'"', '  value       = '}),
      luasnip.insert_node(3, 'value'),
      luasnip.text_node({'', '}'}),
      luasnip.insert_node(0),
    }),

    luasnip.snippet('module', {
      luasnip.text_node('module "'),
      luasnip.insert_node(1, 'name'),
      luasnip.text_node({'" {', '  source = "'}),
      luasnip.insert_node(2, 'source'),
      luasnip.text_node({'"', '', '  '}),
      luasnip.insert_node(0),
      luasnip.text_node({'', '}'}),
    }),

    luasnip.snippet('locals', {
      luasnip.text_node({'locals {', '  '}),
      luasnip.insert_node(1, 'name'),
      luasnip.text_node(' = '),
      luasnip.insert_node(0, 'value'),
      luasnip.text_node({'', '}'}),
    }),
  })
end
-- }}}1

-- HCL Auto Commands {{{1
-- Auto-format on save if enabled
vim.api.nvim_create_autocmd('BufWritePre', {
  buffer = 0,
  callback = function()
    if vim.g.hcl_auto_format then
      format_hcl()
    end
  end,
  desc = 'Auto-format HCL on save'
})

-- Set up Terraform-specific commands
vim.api.nvim_create_autocmd('BufEnter', {
  buffer = 0,
  callback = function()
    if vim.b.hcl_context == 'terraform' then
      vim.keymap.set('n', '<leader>ti', function()
        vim.cmd('split')
        vim.cmd('terminal cd ' .. vim.fn.expand('%:p:h') .. ' && terraform init')
      end, { buffer = true, desc = 'Terraform init' })

      vim.keymap.set('n', '<leader>tv', function()
        vim.cmd('split')
        vim.cmd('terminal cd ' .. vim.fn.expand('%:p:h') .. ' && terraform validate')
      end, { buffer = true, desc = 'Terraform validate' })
    end
  end,
  desc = 'Set up Terraform-specific mappings'
})

-- Highlight interpolation syntax
vim.api.nvim_create_autocmd('BufEnter', {
  buffer = 0,
  callback = function()
    vim.fn.matchadd('Special', '${[^}]*}')
    vim.fn.matchadd('Special', '%{[^}]*}')
  end,
  desc = 'Highlight HCL interpolation'
})
-- }}}1

-- HCL Commands {{{1
vim.api.nvim_create_user_command('HclValidate', function()
  validate_hcl()
end, { desc = 'Validate HCL syntax' })

vim.api.nvim_create_user_command('HclFormat', function()
  format_hcl()
end, { desc = 'Format HCL file' })

vim.api.nvim_create_user_command('HclCheck', function()
  check_hcl_best_practices()
end, { desc = 'Check HCL best practices' })

vim.api.nvim_create_user_command('TerraformPlan', function()
  terraform_plan()
end, { desc = 'Run terraform plan' })

vim.api.nvim_create_user_command('TerraformApply', function()
  terraform_apply()
end, { desc = 'Run terraform apply' })

vim.api.nvim_create_user_command('TerraformInit', function()
  if vim.b.hcl_context == 'terraform' then
    vim.cmd('split')
    vim.cmd('terminal cd ' .. vim.fn.expand('%:p:h') .. ' && terraform init')
  end
end, { desc = 'Run terraform init' })
-- }}}1