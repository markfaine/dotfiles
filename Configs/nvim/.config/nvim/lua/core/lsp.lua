-- vim: foldmethod=marker foldlevel=1

--[[ Language Server Protocol Configuration {{{1
This module configures LSP clients, diagnostics, and language-specific settings.
Optimized for Neovim 11.2 with modern LSP features and performance improvements.

Components:
- Enhanced diagnostic configuration with improved UI
- Modern LSP client capabilities and settings
- Server-specific configurations with better defaults
- Comprehensive key mappings and autocommands
- Management commands for LSP lifecycle
- Performance optimizations and error handling
}}}1 --]]

-- Diagnostic Configuration {{{1
local diagnostic_config = {
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚',
      [vim.diagnostic.severity.WARN] = '󰀪',
      [vim.diagnostic.severity.HINT] = '󰌶',
      [vim.diagnostic.severity.INFO] = '󰋽',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
    },
  },
  virtual_text = {
    enabled = true,
    spacing = 4,
    source = 'if_many',
    prefix = '●',
    severity = { min = vim.diagnostic.severity.WARN },
    format = function(diagnostic)
      return string.format('%s (%s)', diagnostic.message, diagnostic.source or '')
    end,
  },
  virtual_lines = false, -- Disable by default, can be toggled
  update_in_insert = false, -- Better performance
  underline = true,
  severity_sort = true,
  float = {
    focusable = false,
    style = 'minimal',
    border = 'rounded',
    source = true,
    header = '',
    prefix = '',
    suffix = '',
    max_width = math.floor(vim.o.columns * 0.7),
    max_height = math.floor(vim.o.lines * 0.3),
  },
  jump = {
    float = true,
  },
}

vim.diagnostic.config(diagnostic_config)
-- }}}1

-- Enhanced Completion Icons {{{1
local completion_icons = {
  Class = '󰠱 ',
  Color = '󰏘 ',
  Constant = '󰏿 ',
  Constructor = ' ',
  Enum = ' ',
  EnumMember = ' ',
  Event = ' ',
  Field = '󰜢 ',
  File = '󰈙 ',
  Folder = '󰉋 ',
  Function = '󰊕 ',
  Interface = ' ',
  Keyword = '󰌋 ',
  Method = '󰆧 ',
  Module = '󰏗 ',
  Operator = '󰆕 ',
  Property = '󰜢 ',
  Reference = '󰈇 ',
  Snippet = ' ',
  Struct = '󰙅 ',
  Text = '󰉿 ',
  TypeParameter = '󰊄 ',
  Unit = '󰑭 ',
  Value = '󰎠 ',
  Variable = '󰀫 ',
}

-- Apply icons to completion kinds
local completion_kinds = vim.lsp.protocol.CompletionItemKind
for i, kind in ipairs(completion_kinds) do
  completion_kinds[i] = completion_icons[kind] and completion_icons[kind] .. kind or kind
end
-- }}}1

-- Enhanced LSP Capabilities {{{1
local function get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  -- Enhanced completion support
  capabilities.textDocument.completion.completionItem = {
    documentationFormat = { 'markdown', 'plaintext' },
    snippetSupport = true,
    preselectSupport = true,
    insertReplaceSupport = true,
    labelDetailsSupport = true,
    deprecatedSupport = true,
    commitCharactersSupport = true,
    tagSupport = { valueSet = { 1 } },
    resolveSupport = {
      properties = { 'documentation', 'detail', 'additionalTextEdits' },
    },
  }

  -- Enhanced folding support
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = true,
    lineFoldingOnly = true,
  }

  -- Semantic tokens support (will be disabled for performance)
  capabilities.textDocument.semanticTokens = {
    multilineTokenSupport = true,
    overlappingTokenSupport = true,
    tokenTypes = {},
    tokenModifiers = {},
    formats = { 'relative' },
    requests = {
      range = true,
      full = { delta = true },
    },
  }

  -- Inlay hints support
  capabilities.textDocument.inlayHint = {
    dynamicRegistration = true,
    resolveSupport = {
      properties = { 'tooltip', 'textEdits', 'label.tooltip', 'label.command' },
    },
  }

  -- Workspace support
  capabilities.workspace = {
    workspaceFolders = true,
    didChangeWatchedFiles = {
      dynamicRegistration = true,
    },
  }

  return capabilities
end

-- Global LSP configuration
vim.lsp.config('*', {
  capabilities = get_capabilities(),
  on_attach = function(client, bufnr)
    -- Workspace diagnostics integration
    local ok, workspace_diag = pcall(require, 'core.extras.workspace-diagnostic')
    if ok then
      workspace_diag.populate_workspace_diagnostics(client, bufnr)
    end

    -- Enable inlay hints if supported (but disabled by default)
    if client.supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
    end

    -- Set up buffer-local options
    if client.supports_method('textDocument/completion') then
      vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
    end
    if client.supports_method('textDocument/definition') then
      vim.bo[bufnr].tagfunc = 'v:lua.vim.lsp.tagfunc'
    end

    -- Disable formatting for null-ls
    if client.name ~= "null-ls" then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
  end,
})
-- }}}1

-- LSP Key Mappings {{{1
-- Remove conflicting default keybindings
local default_binds = { 'grn', 'gra', 'gri', 'grr' }
for _, bind in ipairs(default_binds) do
  pcall(vim.keymap.del, 'n', bind)
end

-- Enhanced LspAttach autocommand
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then return end

    -- Disable semantic tokens for performance
    client.server_capabilities.semanticTokensProvider = nil

    -- Buffer-local key mappings
    local opts = { buffer = ev.buf, silent = true }
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', opts, { desc = desc }))
    end

    -- Navigation mappings
    map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
    map('n', 'gD', function()
      local ok, def_float = pcall(require, 'core.extras.definition')
      if ok then
        def_float.get_def()
      else
        vim.lsp.buf.declaration()
      end
    end, 'Go to declaration/definition in float')
    map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
    map('n', 'gr', vim.lsp.buf.references, 'Show references')
    map('n', 'gt', vim.lsp.buf.type_definition, 'Go to type definition')

    -- Documentation and help
    pcall(vim.keymap.del, 'n', 'K', { buffer = ev.buf })
    map('n', 'K', function()
      vim.lsp.buf.hover({ border = 'rounded', max_width = 80, max_height = 20 })
    end, 'Show hover documentation')
    map('n', '<C-k>', vim.lsp.buf.signature_help, 'Show signature help')

    -- Code actions and refactoring
    map({ 'n', 'v' }, '<leader>la', vim.lsp.buf.code_action, 'Code actions')
    map('n', '<leader>lr', vim.lsp.buf.rename, 'Rename symbol')
    map('n', '<leader>lf', function()
      vim.lsp.buf.format({ async = true })
    end, 'Format buffer')

    -- Workspace and symbols
    map('n', '<leader>ls', vim.lsp.buf.document_symbol, 'Document symbols')
    map('n', '<leader>lS', vim.lsp.buf.workspace_symbol, 'Workspace symbols')
    map('n', '<leader>lw', vim.lsp.buf.add_workspace_folder, 'Add workspace folder')
    map('n', '<leader>lW', vim.lsp.buf.remove_workspace_folder, 'Remove workspace folder')

    -- LSP management
    map('n', '<leader>li', '<cmd>LspInfo<CR>', 'LSP info')
    map('n', '<leader>lI', '<cmd>Mason<CR>', 'Mason')
    map('n', '<leader>lF', '<cmd>LspFormatToggle<CR>', 'Toggle auto-format')

    -- Diagnostics
    map('n', 'gl', vim.diagnostic.open_float, 'Show line diagnostics')
    map('n', '[d', function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, 'Previous diagnostic')
    map('n', ']d', function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, 'Next diagnostic')
    map('n', '<leader>dq', vim.diagnostic.setloclist, 'Quickfix diagnostics')
    map('n', '<leader>dD', function()
      local ok, diag = pcall(require, 'core.extras.workspace-diagnostic')
      if ok then
        for _, cur_client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          diag.populate_workspace_diagnostics(cur_client, 0)
        end
        vim.notify('Workspace diagnostics populated', vim.log.levels.INFO)
      end
    end, 'Populate workspace diagnostics')
    map('n', '<leader>dv', function()
      local current_config = vim.diagnostic.config()
      vim.diagnostic.config({ virtual_lines = not current_config.virtual_lines })
      vim.notify(
        string.format('Virtual lines: %s', not current_config.virtual_lines and 'enabled' or 'disabled'),
        vim.log.levels.INFO
      )
    end, 'Toggle diagnostic virtual lines')

    -- Inlay hints toggle
    if client.supports_method('textDocument/inlayHint') then
      map('n', '<leader>lh', function()
        local current_setting = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
        vim.lsp.inlay_hint.enable(not current_setting, { bufnr = ev.buf })
        vim.notify(
          string.format('Inlay hints: %s', not current_setting and 'enabled' or 'disabled'),
          vim.log.levels.INFO
        )
      end, 'Toggle inlay hints')
    end

    -- Codelens
    if client.supports_method('textDocument/codeLens') then
      map('n', '<leader>ll', vim.lsp.codelens.run, 'Run codelens')
      map('n', '<leader>lL', vim.lsp.codelens.refresh, 'Refresh codelens')

      -- Auto refresh codelens
      vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
        buffer = ev.buf,
        callback = vim.lsp.codelens.refresh,
      })
    end
  end,
})
-- }}}1

-- Language Server Configurations {{{1
local servers = {
  -- Ansible Language Server
  ansiblels = {
    filetypes = { 'yaml.ansible' },
    root_markers = { '.ansible-lint', 'ansible.cfg', 'galaxy.yml', '.git' },
    single_file_support = true,
    settings = {
      ansible = {
        validation = {
          enabled = true,
          lint = {
            enabled = true,
            path = 'ansible-lint'
          }
        },
        completion = {
          provideRedirectModules = true,
          provideModuleOptionAliases = true,
        },
      }
    }
  },

  -- Bash Language Server
  bashls = {
    cmd = { 'bash-language-server', 'start' },
    filetypes = { 'sh', 'bash', 'zsh' },
    root_markers = { '.git' },
    settings = {
      bashIde = {
        globPattern = vim.env.GLOB_PATTERN or '*@(.sh|.inc|.bash|.command)',
        enableSourceErrorDiagnostics = true,
        shfmt = {
          path = 'shfmt',
          ignoreEditorconfig = false,
        },
      },
    },
    single_file_support = true,
  },

  -- GitLab CI Language Server
  gitlab_ci_ls = {
    name = 'gitlab_ci_ls',
    cmd = { 'gitlab-ci-ls' },
    filetypes = { 'yaml.gitlab' },
    root_markers = { '.gitlab-ci.yml', '.git' },
    init_options = {
      cache = '~/.cache/gitlab-ci-ls/',
      log_path = '~/.cache/gitlab-ci-ls/log/gitlab-ci-ls.log',
      options = {
        dependencies_autocomplete_stage_filtering = false,
      },
    },
    single_file_support = true,
  },

  -- HTML Language Server
  html = {
    name = 'htmlls',
    cmd = { 'vscode-html-language-server', '--stdio' },
    filetypes = { 'html', 'templ' },
    root_markers = { 'package.json', '.git' },
    init_options = {
      configurationSection = { 'html', 'css', 'javascript' },
      embeddedLanguages = {
        css = true,
        javascript = true,
      },
      provideFormatter = true,
    },
    settings = {
      html = {
        format = {
          templating = true,
          wrapLineLength = 120,
          wrapAttributes = 'auto',
        },
        hover = {
          documentation = true,
          references = true,
        },
      },
    },
  },

  -- Lua Language Server (Enhanced for Neovim)
  lua_ls = {
    filetypes = { 'lua' },
    root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
    settings = {
      Lua = {
        telemetry = { enable = false },
        runtime = {
          version = 'LuaJIT',
          pathStrict = true,
        },
        diagnostics = {
          globals = { 'vim', 'it', 'describe', 'before_each', 'after_each' },
          disable = { 'missing-fields' },
          -- Make type-check less intrusive without turning it off
          groupSeverity = { strong = 'Warning', strict = 'Hint' },
          groupFileStatus = vim.tbl_extend('force', {}, {
            ['type-check'] = 'Opened',   -- keep it on…
          }),
        },
        workspace = {
          library = {
            vim.env.VIMRUNTIME,
            vim.fn.stdpath('config'),
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          },
          checkThirdParty = 'Disable',
          maxPreload = 100000,
          preloadFileSize = 10000,
        },
        completion = {
          callSnippet = 'Replace',
          keywordSnippet = 'Replace',
          displayContext = 6,
        },
        hint = {
          enable = true,
          setType = false,
          paramType = true,
          paramName = 'Disable',
          semicolon = 'Disable',
          arrayIndex = 'Disable',
        },
        format = {
          enable = true,
          defaultConfig = {
            indent_style = 'space',
            indent_size = '2',
            continuation_indent_size = '2',
          },
        },
      },
    },
  },

  -- Marksman (Markdown)
  marksman = {
    filetypes = { 'markdown', 'markdown.mdx' },
    root_markers = { '.marksman.toml', 'README.md', '.git' },
    single_file_support = true,
    settings = {
      marksman = {
        completion = {
          wiki = {
            enabled = true,
          },
        },
      },
    },
  },

  -- Python Language Server (Enhanced)
  pylsp = {
    filetypes = { 'python' },
    root_markers = {
      'pyproject.toml',
      'setup.py',
      'setup.cfg',
      'requirements.txt',
      'Pipfile',
      'pyrightconfig.json',
      '.git',
    },
    settings = {
      pylsp = {
        plugins = {
          -- Formatters
          black = {
            enabled = true,
            line_length = 88,
            cache_config = true,
          },
          autopep8 = { enabled = false },
          yapf = { enabled = false },

          -- Linters
          pylint = {
            enabled = true,
            args = {'--max-line-length=88', '--disable=C0111'},
            executable = 'pylint',
          },
          pycodestyle = {
            enabled = false,
            maxLineLength = 88,
          },
          flake8 = {
            enabled = false,
            maxLineLength = 88,
          },
          pyflakes = { enabled = false },

          -- Type checking
          pylsp_mypy = {
            enabled = true,
            live_mode = false,
            dmypy = true,
            strict = false,
          },

          -- Completion and navigation
          jedi_completion = {
            enabled = true,
            fuzzy = true,
            eager = true,
            include_params = true,
          },
          jedi_hover = { enabled = true },
          jedi_references = { enabled = true },
          jedi_signature_help = { enabled = true },
          jedi_symbols = {
            enabled = true,
            all_scopes = true,
            include_import_symbols = true,
          },

          -- Import sorting
          isort = {
            enabled = true,
            profile = 'black',
          },

          -- Rope for refactoring
          rope_completion = {
            enabled = true,
            eager = true,
          },
          rope_autoimport = {
            enabled = true,
            completions = { enabled = true },
            code_actions = { enabled = true },
          },
        },
      },
    },
  },

  -- YAML Language Server
  yamlls = {
    cmd = { 'yaml-language-server', '--stdio' },
    filetypes = { 'yaml', 'yaml.ansible', 'yaml.docker-compose', 'yaml.gitlab' },
    root_markers = { '.git' },
    settings = {
      yaml = {
        keyOrdering = false,
        format = { enable = true, singleQuote = false, bracketSpacing = true },
        validate = true,
        completion = true,
        hover = true,
        schemaStore = {
          enable = true,
          url = 'https://www.schemastore.org/api/json/catalog.json',
        },
        schemas = {
          -- GitHub Workflows
          ['https://json.schemastore.org/github-workflow.json'] = '/.github/workflows/*',
          -- Ansible
          ['https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json'] = '/tasks/**/*.{yml,yaml}',
          ['https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook'] = '/*playbook*.{yml,yaml}',
        },
        customTags = { '!encrypted/pkcs1-oaep', '!vault', '!reference' },
      },
      redhat = { telemetry = { enabled = false } },
    },
    single_file_support = true,
  },
}

-- Configure and enable servers
local default_cmd = {
  pylsp     = { 'pylsp' },                      -- stdio is default; no flag supported
  lua_ls    = { 'lua-language-server' },        -- no stdio flag needed
  marksman  = { 'marksman', 'server' },         -- subcommand required
  bashls    = { 'bash-language-server', 'start' },
  ansiblels = { 'ansible-language-server', '--stdio' },
  yamlls    = { 'yaml-language-server', '--stdio' },
  html      = { 'vscode-html-language-server', '--stdio' },
}

for server_name, config in pairs(servers) do
  -- Use explicit cmd if provided; otherwise a known-safe default; otherwise just the binary
  if not config.cmd then
    config.cmd = default_cmd[server_name] or { server_name }
  end

  if not config.name then
    config.name = server_name
  end

  vim.lsp.config[server_name] = config
  vim.lsp.enable(server_name)
end
-- }}}1

-- Enhanced Management Commands {{{1
local function create_lsp_commands()
  -- Enhanced LspInfo command
  vim.api.nvim_create_user_command('LspInfo', function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
      vim.notify('No LSP clients attached to current buffer', vim.log.levels.INFO)
      vim.cmd('checkhealth vim.lsp')
      return
    end

    local info = {}
    table.insert(info, 'Active LSP clients:')
    for _, client in ipairs(clients) do
      table.insert(info, string.format('  • %s (id: %d)', client.name, client.id))
      if client.workspaceFolders then
        for _, folder in ipairs(client.workspaceFolders) do
          table.insert(info, string.format('    workspace: %s', folder.name))
        end
      end
    end

    vim.notify(table.concat(info, '\n'), vim.log.levels.INFO)
    vim.cmd('checkhealth vim.lsp')
  end, { desc = 'Show LSP information and run health check' })

  -- Enhanced LspStart command
  vim.api.nvim_create_user_command('LspStart', function()
    local bufnr = vim.api.nvim_get_current_buf()
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      vim.lsp.stop_client(client.id)
    end
    vim.cmd('edit!')
    vim.notify('LSP clients restarted for current buffer', vim.log.levels.INFO)
  end, { desc = 'Start/reload LSP clients for current buffer' })

  -- Enhanced LspStop command
  vim.api.nvim_create_user_command('LspStop', function(opts)
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
      vim.notify('No LSP clients to stop', vim.log.levels.WARN)
      return
    end

    local stopped = {}
    for _, client in ipairs(clients) do
      if opts.args == '' or client.name == opts.args then
        client:stop()
        table.insert(stopped, client.name)
      end
    end

    if #stopped > 0 then
      vim.notify('Stopped: ' .. table.concat(stopped, ', '), vim.log.levels.INFO)
    else
      vim.notify('No matching clients found', vim.log.levels.WARN)
    end
  end, {
    desc = 'Stop LSP clients',
    nargs = '?',
    complete = function()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      return vim.tbl_map(function(client) return client.name end, clients)
    end,
  })

  -- Smart LSP restart command
  vim.api.nvim_create_user_command('LspRestart', function(opts)
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
      vim.notify('No LSP clients to restart', vim.log.levels.WARN)
      return
    end

    local client_configs = {}
    for _, client in ipairs(clients) do
      if opts.args == '' or client.name == opts.args then
        client_configs[client.name] = {
          config = client.config,
          buffers = vim.lsp.get_buffers_by_client_id(client.id),
        }
        client:stop()
      end
    end

    -- Wait for clients to stop, then restart
    local timer = vim.uv.new_timer()
    if not timer then
      vim.notify('Failed to create restart timer', vim.log.levels.ERROR)
      return
    end

    timer:start(500, 100, vim.schedule_wrap(function()
      local all_restarted = true
      for name, data in pairs(client_configs) do
        local client_id = vim.lsp.start(data.config)
        if client_id then
          for _, buf in ipairs(data.buffers) do
            vim.lsp.buf_attach_client(buf, client_id)
          end
          vim.notify(string.format('Restarted: %s', name), vim.log.levels.INFO)
          client_configs[name] = nil
        else
          all_restarted = false
        end
      end

      if all_restarted or next(client_configs) == nil then
        if not timer:is_closing() then
          timer:close()
        end
      end
    end))
  end, {
    desc = 'Restart LSP clients',
    nargs = '?',
    complete = function()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      return vim.tbl_map(function(client) return client.name end, clients)
    end,
  })

  -- LSP log management
  vim.api.nvim_create_user_command('LspLog', function()
    local log_path = vim.lsp.log.get_filename()
    if vim.fn.filereadable(log_path) == 1 then
      vim.cmd.vsplit(log_path)
      vim.cmd('normal! G') -- Go to end of file
    else
      vim.notify('LSP log file not found', vim.log.levels.WARN)
    end
  end, { desc = 'Open LSP log file' })

  -- Format toggle command
  vim.api.nvim_create_user_command('LspFormatToggle', function()
    if vim.g.autoformat == nil then
      vim.g.autoformat = true
    end
    vim.g.autoformat = not vim.g.autoformat
    vim.notify(
      string.format('Auto-format on save: %s', vim.g.autoformat and 'enabled' or 'disabled'),
      vim.log.levels.INFO
    )
  end, { desc = 'Toggle auto-formatting on save' })

  -- Diagnostic severity command
  vim.api.nvim_create_user_command("DiagSeverity", function(opts)
    local map = { error=vim.diagnostic.severity.ERROR, warn=vim.diagnostic.severity.WARN, info=vim.diagnostic.severity.INFO, hint=vim.diagnostic.severity.HINT }
    local sev = map[(opts.args or "warn"):lower()] or map.warn
    vim.diagnostic.config({ virtual_text = { severity = { min = sev } } })
  end, { nargs = "?", complete = function() return { "error","warn","info","hint" } end })
end

create_lsp_commands()
-- }}}1

-- Auto-format on save (if enabled) {{{1
vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('LspAutoFormat', { clear = true }),
  callback = function()
    if vim.g.autoformat then
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      for _, client in ipairs(clients) do
        if client.supports_method('textDocument/formatting') then
          vim.lsp.buf.format({ async = false, timeout_ms = 5000 })
          break
        end
      end
    end
  end,
})
-- }}}1

-- Optional: prefer Conform for formatting; disable LSP formatting providers
-- local function maybe_disable_formatting(client)
--   local name = client and client.name or ''
--   if name ~= 'null-ls' then
--     client.server_capabilities.documentFormattingProvider = false
--     client.server_capabilities.documentRangeFormattingProvider = false
--   end
-- end


-- Add/ensure correct cmd for servers that need it:
servers.ansiblels.cmd = { 'ansible-language-server', '--stdio' }
servers.lua_ls.cmd = { 'lua-language-server' }
servers.marksman.cmd = { 'marksman', 'server' }
-- yamlls/bashls/html already have proper cmd in your file

-- Optional: root_dir helper if you want project roots:
local function root_dir(markers)
  return function(fname)
    local path = fname ~= '' and fname or vim.api.nvim_buf_get_name(0)
    local found = vim.fs.find(markers, { path = path, upward = true })[1]
    return found and vim.fs.dirname(found) or vim.loop.cwd()
  end
end

-- Example
servers.yamlls.root_dir = root_dir({ '.git', '.yamllint' })

-- Safe restart command (don’t clobber the built-in :LspStart)
vim.api.nvim_create_user_command('LspRestart', function(opts)
  local bufnr = opts and opts.bang and 0 or vim.api.nvim_get_current_buf()
  for _, c in pairs(vim.lsp.get_active_clients({ bufnr = bufnr })) do
    pcall(c.stop, c, true)
  end
  vim.defer_fn(function()
    vim.cmd('LspStart')
  end, 100)
end, { desc = 'Restart LSP for current buffer; use ! to target all', bang = true })
