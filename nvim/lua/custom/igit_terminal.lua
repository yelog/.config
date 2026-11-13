local terminal = {}

function terminal.toggle_maximize()
  local buffer = vim.api.nvim_get_current_buf()
  if vim.bo[buffer].buftype ~= "terminal" or vim.bo[buffer].filetype ~= "igit" then
    return false
  end

  local channel = vim.bo[buffer].channel
  if channel <= 0 or vim.fn.jobwait({ channel }, 0)[1] ~= -1 then
    vim.notify("IGit terminal has exited. Reopen IGit.", vim.log.levels.WARN)
    return true
  end

  local sent, send_error = pcall(vim.api.nvim_chan_send, channel, "\27[102;13u")
  if not sent then
    vim.notify("Cannot send the IGit pane shortcut: " .. tostring(send_error), vim.log.levels.ERROR)
  end
  return true
end

return terminal
