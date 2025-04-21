---@type vim.lsp.Config
return {
  cmd = { "pylsp" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
    ".git",
  },
  settings = {
    pylsp = {
      plugins = {

        -- formatters
        black = { enabled = true, maxLineLength = 180 },
        autopep8 = { enabled = true, maxLineLength = 180 },

        -- linters
        pylint = { enabled = true, executable = "pylint" },
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
}
