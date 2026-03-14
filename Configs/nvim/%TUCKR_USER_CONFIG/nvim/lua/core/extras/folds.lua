-- Utilities for folds: native foldtext + auto selection of fold method
local M = {}

-- Native, plugin-free fold summary
function M.summary()
  local s, e = vim.v.foldstart, vim.v.foldend
  local first = ''
  for _, l in ipairs(vim.api.nvim_buf_get_lines(0, s - 1, e, false)) do
    if l:match('%S') then
      first = l
        :gsub('^%s*%-%-%s*', '')           -- strip Lua comment leader
        :gsub('%[%[', ''):gsub('%]%]', '') -- strip long-bracket markers
        :gsub('%{%{%{%d*', '')             -- strip {{{n
        :gsub('%}%}%}%d*', '')             -- strip }}}n
        :gsub('^%s+', ''):gsub('%s+$', '')
      break
    end
  end
  if first == '' then first = '(fold)' end
  local n = e - s + 1
  return string.format('%s  •  %d line%s', first, n, n == 1 and '' or 's')
end

local function is_valid_buf(bufnr)
  return type(bufnr) == 'number' and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr)
end

local function file_has_markers(bufnr)
  if not is_valid_buf(bufnr) then
    return false
  end

  -- Read cached result safely
  local cached
  pcall(function() cached = vim.b[bufnr]._has_fold_markers end)
  if cached ~= nil then
    return cached
  end

  local max_scan = math.min(2000, vim.api.nvim_buf_line_count(bufnr))
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, max_scan, false)
  local found = false
  for _, l in ipairs(lines) do
    if l:find('{{{', 1, true) or l:find('}}}', 1, true) then
      found = true
      break
    end
  end

  -- Cache safely
  pcall(function() vim.b[bufnr]._has_fold_markers = found end)
  return found
end

local function treesitter_available(bufnr)
  if not is_valid_buf(bufnr) then
    return false
  end
  local ok_ts, ts = pcall(require, 'vim.treesitter')
  if not ok_ts then return false end
  local ok_parser = pcall(function() ts.get_parser(bufnr) end)
  if not ok_parser then return false end

  -- Optional large-file guard
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path ~= '' then
    local stat = vim.uv.fs_stat(path)
    local limit = tonumber(vim.g.large_file_threshold_bytes or 200 * 1024)
    if stat and stat.size and limit and stat.size > limit then
      return false
    end
  end
  return true
end

local function ufo_loaded()
  return package.loaded['ufo'] ~= nil
end

-- Window-local foldtext helper
local function set_win_foldtext(win, use_ts)
  if ufo_loaded() then
    return -- UFO renders virtual text; skip changing foldtext
  end
  if use_ts and vim.fn.has('nvim-0.10') == 1 then
    vim.api.nvim_set_option_value('foldtext', 'v:lua.vim.treesitter.foldtext()', { win = win })
  else
    vim.api.nvim_set_option_value('foldtext', 'v:lua.require("core.extras.folds").summary()', { win = win })
  end
end

local function apply_to_buf_wins(bufnr, fn)
  if not is_valid_buf(bufnr) then
    return
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      fn(win)
    end
  end
end

-- Public: choose the best folding per buffer
function M.auto_setup(bufnr)
  bufnr = bufnr or 0
  if not is_valid_buf(bufnr) then
    return nil
  end

  if file_has_markers(bufnr) then
    apply_to_buf_wins(bufnr, function(win)
      vim.api.nvim_set_option_value('foldmethod', 'marker', { win = win })
      vim.api.nvim_set_option_value('foldmarker', '{{{,}}}', { win = win })
      set_win_foldtext(win, false)
    end)
    return 'marker'
  end

  if treesitter_available(bufnr) then
    apply_to_buf_wins(bufnr, function(win)
      vim.api.nvim_set_option_value('foldmethod', 'expr', { win = win })
      vim.api.nvim_set_option_value('foldexpr', 'v:lua.vim.treesitter.foldexpr()', { win = win })
      set_win_foldtext(win, true)
    end)
    return 'treesitter'
  end

  -- Fallback: indent
  apply_to_buf_wins(bufnr, function(win)
    vim.api.nvim_set_option_value('foldmethod', 'indent', { win = win })
    set_win_foldtext(win, false)
  end)
  return 'indent'
end

return M
