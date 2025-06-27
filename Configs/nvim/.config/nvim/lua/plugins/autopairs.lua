-- autopairs
-- https://github.com/windwp/nvim-autopairs

return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  config = function()
    local npairs = require 'nvim-autopairs'

    npairs.setup {
      check_ts = true, -- Enable Treesitter if available
      fast_wrap = {},
      disable_filetype = { 'TelescopePrompt', 'vim' },
    }

    -- Custom rule for quotes: don't add pair if already inside a string
    local Rule = require 'nvim-autopairs.rule'

    npairs.add_rules {
      Rule('"', '"'):with_pair(function(opts)
        local line = opts.line
        local col = opts.col

        local before = line:sub(1, col - 1)
        local quote_count = select(2, before:gsub('"', ''))

        -- only insert pair if we're outside a string (even number of quotes)
        -- and next char isn't already a quote
        return (quote_count % 2 == 0) and line:sub(col, col) ~= '"'
      end),

      Rule("'", "'"):with_pair(function(opts)
        local line = opts.line
        local col = opts.col

        local before = line:sub(1, col - 1)
        local quote_count = select(2, before:gsub("'", ''))

        return (quote_count % 2 == 0) and line:sub(col, col) ~= "'"
      end),
    }
  end,
}
