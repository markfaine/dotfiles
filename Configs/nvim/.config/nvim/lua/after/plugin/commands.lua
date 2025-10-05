-- vim: foldmethod=marker foldlevel=1

--[[ Commands: elevated write (SudoWrite) {{{1
Save a read-only/root-owned file without leaving Neovim.

Behavior:
- If SUDO_ASKPASS is set, use sudo -A in a background job (no terminal).
- Else, open a temporary terminal that prompts for the sudo password.
- Always handles spaces in paths; cleans up temp files; marks buffer unmodified.
}}}1 --]]

local function shellescape(path)
  return vim.fn.shellescape(path)
end

local function write_tmp_from_buf(bufnr)
  local tmp = vim.fn.tempname()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  -- writefile expects a list; returns 0 on success
  local ok = vim.fn.writefile(lines, tmp) == 0
  return ok and tmp or nil
end

local function reload_and_finalize(bufnr, tmp, msg)
  if tmp and tmp ~= '' then pcall(vim.fn.delete, tmp) end
  -- Buffer already has the content we wrote out; clear modified flag
  if vim.api.nvim_buf_is_valid(bufnr) then
    pcall(function() vim.bo[bufnr].modified = false end)
  end
  if msg then vim.notify(msg, vim.log.levels.INFO) end
end

-- Core implementation {{{1
local function sudo_write()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)

  -- Require a file path; prompt if missing
  if path == nil or path == '' then
    vim.ui.input({ prompt = 'Write as (absolute path): ' }, function(input)
      if input and input ~= '' then
        vim.api.nvim_buf_set_name(bufnr, input)
        vim.schedule(sudo_write)
      else
        vim.notify('SudoWrite aborted: no path provided', vim.log.levels.WARN)
      end
    end)
    return
  end

  local tmp = write_tmp_from_buf(bufnr)
  if not tmp then
    vim.notify('SudoWrite failed: could not write temp file', vim.log.levels.ERROR)
    return
  end

  local sh_dst = shellescape(path)
  local sh_tmp = shellescape(tmp)

  -- Fast-path: askpass available (non-interactive job)
  if os.getenv('SUDO_ASKPASS') then
    -- Use a direct sudo -A sh -c 'cat tmp > dest' to avoid terminal UI
    local cmd = { 'sudo', '-A', 'sh', '-c', string.format('cat %s > %s', sh_tmp, sh_dst) }

    -- Prefer your async runner if available; otherwise use vim.system directly
    local ok_util, util = pcall(require, 'core.extras.utility')
    if ok_util and type(util.run) == 'function' then
      util.run(cmd, function()
        reload_and_finalize(bufnr, tmp, 'Wrote (sudo -A): ' .. path)
      end, function(err)
        vim.notify('SudoWrite failed:\n' .. (err or ''), vim.log.levels.ERROR)
      end)
    else
      vim.system(cmd, { text = true }, function(obj)
        vim.schedule(function()
          if obj.code == 0 then
            reload_and_finalize(bufnr, tmp, 'Wrote (sudo -A): ' .. path)
          else
            vim.notify('SudoWrite failed:\n' .. (obj.stderr or obj.stdout or ''), vim.log.levels.ERROR)
          end
        end)
      end)
    end
    return
  end

  -- Fallback: interactive terminal (password prompt) {{{2
  -- Open a split terminal that runs: sudo tee -- <dest> < <tmp> > /dev/null
  -- Close it when the command finishes; then finalize.
  local term_cmd = string.format('sudo tee -- %s < %s > /dev/null', sh_dst, sh_tmp)

  -- Create a small split for the terminal
  vim.cmd('belowright 12split')
  local term_win = vim.api.nvim_get_current_win()
  local term_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(term_win, term_buf)

  vim.fn.termopen(term_cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          reload_and_finalize(bufnr, tmp, 'Wrote (sudo): ' .. path)
        else
          vim.notify('SudoWrite failed (see terminal output)', vim.log.levels.ERROR)
        end
        -- Close the terminal window if it’s still valid and visible
        if vim.api.nvim_win_is_valid(term_win) then
          pcall(vim.api.nvim_win_close, term_win, true)
        end
      end)
    end,
  })
  vim.cmd('startinsert')
  -- }}}2
end
-- }}}1

-- Smart write: try normal write, fallback to sudo {{{1
local function smart_write(opts)
  local bang = opts and opts.bang
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr) or ''

  -- If file seems writable, attempt a normal write first
  local writable = (path ~= '' and vim.fn.filewritable(path) == 1) or path == ''
  if writable then
    local ok = pcall(function()
      vim.cmd((bang and 'write!' or 'write'))
    end)
    if ok then
      return
    end
  end

  -- Fallback to sudo write
  return sudo_write()
end
-- }}}1

-- User commands {{{1
vim.api.nvim_create_user_command('SudoWrite', sudo_write, { desc = 'Write current file with sudo' })

-- Make :W a smart write (normal if possible, sudo otherwise)
vim.api.nvim_create_user_command('W', smart_write, {
  bang = true,
  desc = 'Smart write (normal or sudo when needed)',
})

-- Optional: smart write + quit
vim.api.nvim_create_user_command('Wq', function(opts)
  smart_write(opts)
  vim.cmd('quit')
end, { bang = true, desc = 'Smart write then quit' })

vim.api.nvim_create_user_command('WQ', function(opts)
  smart_write(opts)
  vim.cmd('quit')
end, { bang = true, desc = 'Smart write then quit' })
-- }}}1