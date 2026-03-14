local M = {}

function M.run(cmd, on_ok, on_err)
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code == 0 then
        if on_ok then on_ok(res.stdout) end
      else
        if on_err then on_err((res.stdout or '') .. (res.stderr or '')) end
      end
    end)
  end)
end

return M