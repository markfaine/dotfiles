local o = vim.o

-- Disable mouse support
o.mouse = ""

-- Some plugins require this to be explicitly set
vim.api.nvim_command "filetype plugin on"

--   The time in milliseconds that is waited for a key code or mapped
--   key sequence to complete.
o.ttimeoutlen = 10
-- Time in milliseconds to wait for a mapped sequence to complete.
o.timeoutlen = 500

-- Reserve a space in the gutter
-- This will avoid an annoying layout shift in the screen
vim.opt.signcolumn = "yes"

-- diff options
vim.opt.diffopt = {
  "internal",
  "filler",
  "closeoff",
  "context:12",
  "algorithm:histogram",
  "linematch:200",
  "indent-heuristic",
  "iwhite",
}

-- Dynamic terminal padding
local autocmd = vim.api.nvim_create_autocmd
autocmd("VimEnter", {
  command = ":silent !kitty @ set-spacing padding=0 margin=0",
})

autocmd("VimLeavePre", {
  command = ":silent !kitty @ set-spacing padding=20 margin=10",
})

-- WSL clipboard
vim.o.clipboard = ""
vim.g.clipboard = {
  name = "WslClipboard",
  copy = {
    ["+"] = "clip.exe",
    ["*"] = "clip.exe",
  },
  paste = {
    ["+"] = 'pwsh.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    ["*"] = 'pwsh.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  },
  cache_enabled = 0,
}

-- Enable indent blank line plugin in all new buffers
require("ibl").setup_buffer(0, { enabled = true })

-- Remove trailing whitespaces
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("trim_whitespaces", { clear = true }),
  desc = "Trim trailing white spaces",
  pattern = "sh,bash,rst,c,cpp,lua,java,go,php,javascript,make,python,rust,perl,sql,markdown",
  callback = function()
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "<buffer>",
      -- Trim trailing whitespaces
      callback = function()
        -- Save cursor position to restore later
        local curpos = vim.api.nvim_win_get_cursor(0)
        -- Search and replace trailing whitespaces
        vim.cmd [[keeppatterns %s/\s\+$//e]]
        vim.api.nvim_win_set_cursor(0, curpos)
      end,
    })
  end,
})
