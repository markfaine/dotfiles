-- vim: foldmethod=marker foldlevel=1

--[[ Dockerfile Configuration {{{1
Enhanced editing experience for Dockerfiles with validation,
best practices checking, image building tools, and smart mappings.
}}}1 --]]

-- Dockerfile Settings {{{1
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true
vim.opt_local.smartindent = true

-- Dockerfile-specific options
vim.opt_local.textwidth = 120
vim.opt_local.colorcolumn = '121'
vim.opt_local.wrap = false
vim.opt_local.foldmethod = 'marker'
vim.opt_local.foldlevel = 1

-- Show whitespace (important for Dockerfiles)
vim.opt_local.list = true
vim.opt_local.listchars = {
  tab = '»·',
  trail = '·',
  extends = '❯',
  precedes = '❮',
  nbsp = '⦸',
}

-- Enable spell checking for comments
vim.opt_local.spell = true
vim.opt_local.spelllang = 'en_us'
-- }}}1

-- Smart Dockerfile Mappings {{{1
-- Quick instruction insertion
vim.keymap.set('i', '<C-i>', function()
  local instructions = {
    'FROM', 'RUN', 'CMD', 'LABEL', 'EXPOSE', 'ENV',
    'ADD', 'COPY', 'ENTRYPOINT', 'VOLUME', 'USER',
    'WORKDIR', 'ARG', 'ONBUILD', 'STOPSIGNAL', 'HEALTHCHECK'
  }

  vim.ui.select(instructions, {
    prompt = 'Select Dockerfile instruction:',
  }, function(choice)
    if choice then
      local line = vim.api.nvim_get_current_line()
      vim.api.nvim_set_current_line(line .. choice .. ' ')
      vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], #line + #choice + 1 })
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert Dockerfile instruction' })

-- Multi-stage build helper
vim.keymap.set('i', '<C-s>', function()
  local indent = string.rep(' ', vim.fn.indent('.'))
  return '# Stage: \nFROM  AS \n' .. indent
end, { buffer = true, expr = true, desc = 'Multi-stage build template' })

-- Common patterns
vim.keymap.set('i', '<C-r>', function()
  local patterns = {
    'RUN apt-get update && apt-get install -y',
    'RUN yum update -y && yum install -y',
    'RUN apk update && apk add --no-cache',
    'RUN pip install --no-cache-dir',
    'RUN npm install --production',
    'COPY --from=',
    'COPY --chown=',
    'RUN --mount=type=cache,target='
  }

  vim.ui.select(patterns, {
    prompt = 'Select common pattern:',
  }, function(choice)
    if choice then
      local line = vim.api.nvim_get_current_line()
      vim.api.nvim_set_current_line(line .. choice .. ' ')
      vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], #line + #choice + 1 })
    end
  end)

  return ''
end, { buffer = true, expr = true, desc = 'Insert common Docker pattern' })

-- Navigation mappings
vim.keymap.set('n', ']]', '/^FROM\\|^# Stage<CR>',
  { buffer = true, desc = 'Next stage' })
vim.keymap.set('n', '[[', '?^FROM\\|^# Stage<CR>',
  { buffer = true, desc = 'Previous stage' })
vim.keymap.set('n', '}', '/^RUN\\|^COPY\\|^ADD<CR>',
  { buffer = true, desc = 'Next instruction' })
vim.keymap.set('n', '{', '?^RUN\\|^COPY\\|^ADD<CR>',
  { buffer = true, desc = 'Previous instruction' })
-- }}}1

-- Docker Tools and Validation {{{1
local function build_image()
  local dockerfile_dir = vim.fn.expand('%:p:h')
  local default_tag = vim.fn.fnamemodify(dockerfile_dir, ':t'):lower()

  vim.ui.input({
    prompt = 'Image tag: ',
    default = default_tag
  }, function(tag)
    if tag and tag ~= '' then
      vim.cmd('split')
      vim.cmd('terminal cd ' .. dockerfile_dir .. ' && docker build -t ' .. tag .. ' .')
    end
  end)
end

local function lint_dockerfile()
  local run = require('core.utility').run
  local current_file = vim.fn.expand('%:p')

  if vim.fn.executable('hadolint') == 1 then
    run({ 'hadolint', current_file },
      function() vim.notify('✓ Dockerfile passes hadolint checks', vim.log.levels.INFO) end,
      function(err) vim.notify('Hadolint issues:\n' .. err, vim.log.levels.WARN) end)
  else
    vim.notify('hadolint not available. Install with: brew install hadolint', vim.log.levels.ERROR)
  end
end

local function check_best_practices()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local issues = {}
  local has_from = false
  local has_user = false
  local apt_update_without_install = false

  for i, line in ipairs(lines) do
    local trimmed = vim.trim(line)

    -- Check for FROM instruction
    if trimmed:match('^FROM ') then
      has_from = true
      -- Check for latest tag
      if trimmed:match(':latest') or not trimmed:match(':') then
        table.insert(issues, string.format('Line %d: Avoid using :latest tag', i))
      end
    end

    -- Check for USER instruction
    if trimmed:match('^USER ') then
      has_user = true
    end

    -- Check for apt-get best practices
    if trimmed:match('^RUN.*apt%-get update') then
      if not trimmed:match('apt%-get install') then
        apt_update_without_install = true
        table.insert(issues, string.format('Line %d: apt-get update should be combined with install', i))
      end
      if not trimmed:match('%-y') then
        table.insert(issues, string.format('Line %d: Missing -y flag for apt-get', i))
      end
    end

    -- Check for cache cleanup
    if trimmed:match('apt%-get install') and not trimmed:match('rm.*apt') then
      table.insert(issues, string.format('Line %d: Consider cleaning apt cache', i))
    end

    -- Check for COPY vs ADD
    if trimmed:match('^ADD ') and not trimmed:match('%.tar') then
      table.insert(issues, string.format('Line %d: Consider using COPY instead of ADD', i))
    end

    -- Check for specific version pinning
    if trimmed:match('pip install') and not trimmed:match('==') then
      table.insert(issues, string.format('Line %d: Consider pinning package versions', i))
    end
  end

  if not has_from then
    table.insert(issues, 'Missing FROM instruction')
  end

  if not has_user then
    table.insert(issues, 'Consider adding USER instruction for security')
  end

  if #issues == 0 then
    vim.notify('✓ No obvious best practice issues found', vim.log.levels.INFO)
  else
    vim.notify('Best practice suggestions:\n' .. table.concat(issues, '\n'), vim.log.levels.WARN)
  end
end

local function run_container()
  vim.ui.input({ prompt = 'Image name: ' }, function(image)
    if image and image ~= '' then
      vim.ui.input({
        prompt = 'Additional docker run options: ',
        default = '-it --rm'
      }, function(options)
        vim.cmd('split')
        vim.cmd('terminal docker run ' .. (options or '-it --rm') .. ' ' .. image)
      end)
    end
  end)
end

local function docker_compose_up()
  local dockerfile_dir = vim.fn.expand('%:p:h')
  local compose_file = dockerfile_dir .. '/docker-compose.yml'

  if vim.fn.filereadable(compose_file) == 1 then
    vim.cmd('split')
    vim.cmd('terminal cd ' .. dockerfile_dir .. ' && docker-compose up')
  else
    vim.notify('No docker-compose.yml found in current directory', vim.log.levels.WARN)
  end
end

local function analyze_image_size()
  vim.ui.input({ prompt = 'Image name to analyze: ' }, function(image)
    if image and image ~= '' then
      if vim.fn.executable('dive') == 1 then
        vim.cmd('split')
        vim.cmd('terminal dive ' .. image)
      else
        vim.cmd('split')
        vim.cmd('terminal docker history ' .. image)
      end
    end
  end)
end

-- Docker tool mappings
vim.keymap.set('n', '<leader>db', build_image, { buffer = true, desc = 'Build Docker image' })
vim.keymap.set('n', '<leader>dl', lint_dockerfile, { buffer = true, desc = 'Lint Dockerfile' })
vim.keymap.set('n', '<leader>dc', check_best_practices, { buffer = true, desc = 'Check best practices' })
vim.keymap.set('n', '<leader>dr', run_container, { buffer = true, desc = 'Run container' })
vim.keymap.set('n', '<leader>du', docker_compose_up, { buffer = true, desc = 'Docker compose up' })
vim.keymap.set('n', '<leader>da', analyze_image_size, { buffer = true, desc = 'Analyze image size' })
-- }}}1

-- Dockerfile Snippets {{{1
-- Set up snippet integration if LuaSnip is available
local ok, luasnip = pcall(require, 'luasnip')
if ok then
  luasnip.add_snippets('dockerfile', {
    luasnip.snippet('base', {
      luasnip.text_node('FROM '),
      luasnip.insert_node(1, 'ubuntu:22.04'),
      luasnip.text_node({'', '', 'WORKDIR /app', '', 'COPY . .', '', 'RUN '}),
      luasnip.insert_node(2, 'apt-get update && apt-get install -y'),
      luasnip.text_node({'', '', 'CMD '}),
      luasnip.insert_node(0, '["echo", "Hello World"]'),
    }),

    luasnip.snippet('multistage', {
      luasnip.text_node('# Build stage'),
      luasnip.text_node({'', 'FROM '}),
      luasnip.insert_node(1, 'node:18-alpine'),
      luasnip.text_node(' AS builder'),
      luasnip.text_node({'', 'WORKDIR /app', 'COPY package*.json ./', 'RUN npm ci --only=production', '', '# Production stage', 'FROM '}),
      luasnip.insert_node(2, 'node:18-alpine'),
      luasnip.text_node({'', 'WORKDIR /app', 'COPY --from=builder /app/node_modules ./node_modules', 'COPY . .', 'CMD '}),
      luasnip.insert_node(0, '["npm", "start"]'),
    }),

    luasnip.snippet('security', {
      luasnip.text_node({'RUN groupadd -r '}),
      luasnip.insert_node(1, 'appuser'),
      luasnip.text_node(' && useradd -r -g '),
      luasnip.rep(1),
      luasnip.text_node(' '),
      luasnip.rep(1),
      luasnip.text_node({'', 'USER '}),
      luasnip.rep(1),
      luasnip.text_node({'', 'COPY --chown='}),
      luasnip.rep(1),
      luasnip.text_node(':'),
      luasnip.rep(1),
      luasnip.text_node(' '),
      luasnip.insert_node(0, '. .'),
    }),

    luasnip.snippet('healthcheck', {
      luasnip.text_node('HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\'),
      luasnip.text_node({'', '  CMD '}),
      luasnip.insert_node(0, 'curl -f http://localhost:8080/health || exit 1'),
    }),
  })
end
-- }}}1

-- Dockerfile Auto Commands {{{1
-- Auto-uppercase Dockerfile instructions
vim.api.nvim_create_autocmd('InsertLeave', {
  buffer = 0,
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local instructions = {
      'from', 'run', 'cmd', 'label', 'expose', 'env',
      'add', 'copy', 'entrypoint', 'volume', 'user',
      'workdir', 'arg', 'onbuild', 'stopsignal', 'healthcheck'
    }

    for _, instruction in ipairs(instructions) do
      if line:match('^%s*' .. instruction .. '%s') then
        local new_line = line:gsub('^(%s*)' .. instruction, '%1' .. instruction:upper())
        vim.api.nvim_set_current_line(new_line)
        break
      end
    end
  end,
  desc = 'Auto-uppercase Dockerfile instructions'
})

-- Highlight long RUN commands
vim.api.nvim_create_autocmd('BufEnter', {
  buffer = 0,
  callback = function()
    -- Add custom highlights for long RUN commands if desired
    vim.fn.matchadd('Todo', 'RUN.*\\\\.*\\n.*\\\\.*\\n.*\\\\')
  end,
  desc = 'Highlight complex RUN commands'
})

-- Auto-add .dockerignore reminder
vim.api.nvim_create_autocmd('BufWritePost', {
  buffer = 0,
  callback = function()
    local dockerfile_dir = vim.fn.expand('%:p:h')
    local dockerignore = dockerfile_dir .. '/.dockerignore'

    if vim.fn.filereadable(dockerignore) == 0 then
      vim.notify('Consider creating a .dockerignore file', vim.log.levels.INFO)
    end
  end,
  desc = 'Remind about .dockerignore'
})
-- }}}1

-- Docker Commands {{{1
vim.api.nvim_create_user_command('DockerBuild', function(opts)
  local tag = opts.args ~= '' and opts.args or vim.fn.fnamemodify(vim.fn.expand('%:p:h'), ':t'):lower()
  build_image()
end, {
  nargs = '?',
  desc = 'Build Docker image from current Dockerfile'
})

vim.api.nvim_create_user_command('DockerLint', function()
  lint_dockerfile()
end, { desc = 'Lint current Dockerfile with hadolint' })

vim.api.nvim_create_user_command('DockerRun', function(opts)
  run_container()
end, {
  nargs = '?',
  desc = 'Run Docker container'
})

vim.api.nvim_create_user_command('DockerCompose', function()
  docker_compose_up()
end, { desc = 'Run docker-compose up' })
-- }}}1