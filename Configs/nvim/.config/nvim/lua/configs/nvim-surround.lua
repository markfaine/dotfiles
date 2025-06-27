--- Custom mapping for creating folds
vim.keymap.set('v', 'F', function()
  local input = vim.fn.input 'Fold Text: '
  local commentstr = vim.bo.commentstring
  local foldstart = ' {{{'
  local foldend = ' }}}'
  if input ~= '' then
    local start_comment = string.gsub(commentstr, '%%s', input .. ' ' .. foldstart)
    local startpos = vim.api.nvim_buf_get_mark(0, '<')[1]
    local endpos = vim.api.nvim_buf_get_mark(0, '>')[1]
    vim.api.nvim_buf_set_lines(0, startpos - 1, startpos - 1, false, { start_comment })
    local end_comment = string.gsub(commentstr, '%%s', 'End ' .. input .. ' ' .. foldend)
    vim.api.nvim_buf_set_lines(0, endpos + 1, endpos + 1, false, { end_comment })
  else
    print 'The fold text is required!'
  end
end, { desc = 'Create a fold' })
