--- Blatantly ripped off from https://github.com/terrortylor/nvim-comment/blob/main/lua/nvim_comment.lua
--- I don't really need the full plugin but the wrapper function could be useful in a lot of places

local M = {}
-- Comment Wrapper }}}
function M.get_comment_wrapper()
  local cs = vim.api.nvim_get_option_value('commentstring', {})

  -- Make sure comment string is understood
  if cs:find '%%s' then
    local left, right = cs:match '^(.*)%%s(.*)'
    if right == '' then
      right = nil
    end

    -- Left comment markers should have padding as linters prefer
    if M.config.marker_padding then
      if not left:match '%s$' then
        left = left .. ' '
      end
      if right and not right:match '^%s' then
        right = ' ' .. right
      end
    end

    return left, right
  else
    vim.api.nvim_command('echom "Commentstring not understood: ' .. cs .. '"')
  end
end
-- End Comment Wrapper {{{
