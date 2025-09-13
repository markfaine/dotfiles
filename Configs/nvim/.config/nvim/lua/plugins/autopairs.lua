-- vim: foldmethod=marker foldlevel=1

-- autopairs
-- https://github.com/windwp/nvim-autopairs
return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter', -- load only when typing
  config = function()
    local npairs = require('nvim-autopairs')

    npairs.setup({
      check_ts = true,
      ts_config = {
        lua        = { 'string' },
        javascript = { 'template_string' },
        typescript = { 'template_string' },
        python     = { 'string' },
        markdown   = { 'fenced_code_block' },
      },
      disable_in_macro = true,
      disable_in_replace_mode = true,
      enable_check_bracket_line = true,
      ignored_next_char = string.gsub([[ [%w%%%'%[%"%.] ]], '%s+', ''),
      disable_filetype = { 'TelescopePrompt', 'vim', 'snacks_input', 'snacks_picker' },
      fast_wrap = {
        map = '<M-e>',
        chars = { '{', '[', '(', '"', "'", '`' },
        pattern = [=[[%'%"%>%]%)%}%,]]=],
        end_key = '$',
        keys = 'qwertyuiopasdfghjklzxcvbnm',
        check_comma = true,
        highlight = 'Search',
        highlight_grey = 'Comment',
      },
    })

    -- nvim-cmp integration
    local has_cmp, cmp = pcall(require, 'cmp')
    if has_cmp then
      local cmp_ap = require('nvim-autopairs.completion.cmp')
      cmp.event:on('confirm_done', cmp_ap.on_confirm_done())
    end

    -- Custom rules
    local Rule = require('nvim-autopairs.rule')
    local cond = require('nvim-autopairs.conds')

    npairs.add_rules({
      Rule('"', '"')
        :with_pair(function(opts)
          local line, col = opts.line, opts.col
          local before = line:sub(1, col - 1)
          local count = select(2, before:gsub('"', ''))
          return (count % 2 == 0) and line:sub(col, col) ~= '"'
        end)
        :with_move(cond.none()),
      Rule("'", "'")
        :with_pair(function(opts)
          local line, col = opts.line, opts.col
          local before = line:sub(1, col - 1)
          local count = select(2, before:gsub("'", ''))
          return (count % 2 == 0) and line:sub(col, col) ~= "'"
        end)
        :with_move(cond.none()),
    })

    npairs.add_rules({
      Rule('`', '`')
        :with_pair(function(opts)
          local line, col = opts.line, opts.col
          return line:sub(col, col) ~= '`'
        end)
        :with_move(cond.none()),
    }, { 'markdown', 'md', 'gitcommit' })

    local function space_in_pair(open, close)
      return Rule(' ', ' ')
        :with_pair(function(opts)
          local pair = opts.line:sub(opts.col - 1, opts.col)
          return pair == open .. close
        end)
        :with_move(cond.none())
        :with_cr(cond.none())
        :with_del(function(opts)
          local col = opts.col
          return opts.line:sub(col - 1, col + 1) == open .. ' ' and opts.line:sub(col, col + 1) == ' ' .. close
        end)
        :use_key(' ')
    end

    npairs.add_rules({
      space_in_pair('(', ')'),
      space_in_pair('[', ']'),
      space_in_pair('{', '}'),
    })

    npairs.add_rules({
      Rule('<', '>')
        :with_pair(function(opts)
          return opts.line:sub(opts.col, opts.col) ~= '>'
        end),
    }, { 'html', 'xml', 'markdown' })
  end,
}
