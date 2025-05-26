return {
  cmd = { "ansible-language-server", "--stdio" },
  settings = {
    ansible = {
      python = {
        interpreterPath = "python",
      },
      ansible = {
        path = "ansible",
      },
      executionEnvironment = {
        enabled = false,
      },
      validation = {
        enabled = true,
        lint = {
          enabled = true,
	  arguments = { "--fix=none" },
          path = "ansible-lint",
        },
      },
    },
  },
  filetypes = { "yaml.ansible" },
  root_markers = { ".git", ".ansible-lint", "galaxy.yml" },
  single_file_support = true,
}
