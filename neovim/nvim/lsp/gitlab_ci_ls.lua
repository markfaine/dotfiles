return {
  cmd = { 'gitlab-ci-ls' },
  init_options = {
    cache = '~/.cache/gitlab-ci-ls/',
    log_path = '~/.cache/gitlab-ci-ls/log/gitlab-ci-ls.log',
    options = {
      dependencies_autocomplete_stage_filtering = false,
    },
  },
},
