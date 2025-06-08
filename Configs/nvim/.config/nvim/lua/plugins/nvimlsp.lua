return {
  -- Main LSP Configuration
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      {
        'williamboman/mason.nvim',
        opts = {},
      },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },
      -- Allows extra capabilities provided by blink.cmp
      'saghen/blink.cmp',
    },
    --
    -- Autocommands on LSP attach for keymaps related to LSPs
    --
    config = function()
      -- vim.api.nvim_create_autocmd('LspAttach', {
      --   group = vim.api.nvim_create_augroup('mf-lsp-attach', { clear = true }),
      --   callback = function(event)
      --     local map = function(keys, func, desc, mode)
      --       mode = mode or 'n'
      --       vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      --     end
      --
      --     -- Rename the variable under your cursor.
      --     --  Most Language Servers support renaming across files, etc.
      --     map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
      --
      --     -- Execute a code action, usually your cursor needs to be on top of an error
      --     -- or a suggestion from your LSP for this to activate.
      --     map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
      --
      --     -- Find references for the word under your cursor.
      --     map('grr', '<cmd>:PickMe lsp_references<cr>', '[G]oto [R]eferences')
      --
      --     -- Jump to the implementation of the word under your cursor.
      --     --  Useful when your language has ways of declaring types without an actual implementation.
      --     map('gri', '<cmd>:PickMe lsp_implementations<cr>', '[G]oto [I]mplementations')
      --
      --     -- Jump to the definition of the word under your cursor.
      --     --  This is where a variable was first declared, or where a function is defined, etc.
      --     --  To jump back, press <C-t>.
      --     map('grd', '<cmd>:PickMe lsp_definitions<cr>', '[G]oto [D]efinition')
      --
      --     -- WARN: This is not Goto Definition, this is Goto Declaration.
      --     --  For example, in C this would take you to the header.
      --     map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
      --
      --     -- Fuzzy find all the symbols in your current document.
      --     --  Symbols are things like variables, functions, types, etc.
      --     map('gO', '<cmd>:PickMe lsp_document_symbols<cr>', 'Open Document Symbols')
      --
      --     -- Fuzzy find all the symbols in your current workspace.
      --     --  Similar to document symbols, except searches over your entire project.
      --     map('gW', '<cmd>:PickMe lsp_workspace_symbols<cr>', 'Open Workspace Symbols')
      --
      --     -- Jump to the type of the word under your cursor.
      --     --  Useful when you're not sure what type a variable is and you want to see
      --     --  the definition of its *type*, not where it was *defined*.
      --     map('grt', '<cmd>:PickMe lsp_type_definitions<cr>', '[G]oto [T]ype Definition')
      --
      --     -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
      --     ---@param client vim.lsp.Client
      --     ---@param method vim.lsp.protocol.Method
      --     ---@param bufnr? integer some lsp support methods only in specific files
      --     ---@return boolean
      --     local function client_supports_method(client, method, bufnr)
      --       if vim.fn.has 'nvim-0.11' == 1 then
      --         return client:supports_method(method, bufnr)
      --       else
      --         return client.supports_method(method, { bufnr = bufnr })
      --       end
      --     end
      --
      --     local client = vim.lsp.get_client_by_id(event.data.client_id)
      --     if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      --       local highlight_augroup = vim.api.nvim_create_augroup('mf-lsp-highlight', { clear = false })
      --       vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      --         buffer = event.buf,
      --         group = highlight_augroup,
      --         callback = vim.lsp.buf.document_highlight,
      --       })
      --
      --       vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      --         buffer = event.buf,
      --         group = highlight_augroup,
      --         callback = vim.lsp.buf.clear_references,
      --       })
      --
      --       vim.api.nvim_create_autocmd('LspDetach', {
      --         group = vim.api.nvim_create_augroup('mf-lsp-detach', { clear = true }),
      --         callback = function(event2)
      --           vim.lsp.buf.clear_references()
      --           vim.api.nvim_clear_autocmds { group = 'mf-lsp-highlight', buffer = event2.buf }
      --         end,
      --       })
      --     end
      --     if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      --       map('<leader>th', function()
      --         vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      --       end, '[T]oggle Inlay [H]ints')
      --     end
      --   end,
      -- })
      vim.diagnostic.config {
        virtual_lines = { current_line = true },
        virtual_text = false,
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = diagnostic.message,
              [vim.diagnostic.severity.WARN] = diagnostic.message,
              [vim.diagnostic.severity.INFO] = diagnostic.message,
              [vim.diagnostic.severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      local servers = {
        ansiblels = {
          cmd = { 'ansible-language-server', '--stdio' },
          filetypes = { 'yaml.ansible' },
          root_markers = { '.git', '.ansible-lint', 'galaxy.yml' },
          single_file_support = true,
        },
        bashls = {
          cmd = { 'bash-language-server', 'start' },
          filetypes = { 'bash', 'sh' },
          root_markers = function(fname)
            return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
          end,
          settings = {
            bashIde = {
              globPattern = vim.env.GLOB_PATTERN or '*@(.sh|.inc|.bash|.command)',
            },
          },
          single_file_support = true,
        },
        yamlls = {
          cmd = { 'yaml-language-server', '--stdio' },
          filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab' },
          root_markers = { '.git' },
          settings = {
            -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
            redhat = { telemetry = { enabled = false } },
          },
          single_file_support = true,
        },
        pylsp = {
          cmd = { 'pylsp' },
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

                -- formatters
                black = { enabled = true, maxLineLength = 180 },
                autopep8 = { enabled = true, maxLineLength = 180 },

                -- linters
                pylint = { enabled = true, executable = 'pylint' },
                pycodestyle = { enabled = false, maxLineLength = 180 },
                flake8 = { enabled = false, maxLineLength = 180 },
                pyflakes = { enabled = false, maxLineLength = 180 },

                -- type checker
                pylsp_mypy = { enabled = true },
                -- auto completion
                jedi_completion = { fuzzy = true },

                -- import sorting
                pyls_isort = { enabled = true },
              },
            },
          },
          single_file_support = true,
        },
        gitlab_cs_ls = {
          cmd = { 'gitlab-ci-ls' },
          init_options = {
            cache = '~/.cache/gitlab-ci-ls/',
            log_path = '~/.cache/gitlab-ci-ls/log/gitlab-ci-ls.log',
            options = {
              dependencies_autocomplete_stage_filtering = false,
            },
          },
        },
        lua_ls = {
          cmd = { 'lua-language-server' },
          filetypes = { 'lua' },
          --root_markers = util.root_pattern(root_files),
          single_file_support = true,
          log_level = vim.lsp.protocol.MessageType.Warning,
          settings = {
            Lua = {
              diagnostics = { globals = { 'vim' } },
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },
      }
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })
    end,
  },
}
