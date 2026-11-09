if vim.bo.buftype ~= "terminal" then return end

local buf = vim.api.nvim_get_current_buf()
-- Keep the resumable terminal out of the editor's buffer list.
vim.bo[buf].buflisted = false

for _, key in ipairs({ "h", "j", "k", "l" }) do
  for _, shift in ipairs({ false, true }) do
    local lhs = ("<D-C-%s%s>"):format(shift and "S-" or "", key)
    -- Preserve Cmd and Ctrl when sending the chord to the terminal job.
    local bytes = ("\27[%d;%du"):format(key:byte(), shift and 14 or 13)
    vim.keymap.set("t", lhs, function()
      local chan = vim.bo[buf].channel
      if chan > 0 then pcall(vim.api.nvim_chan_send, chan, bytes) end
    end, { buffer = buf, desc = "Send pane key to IGit" })
  end
end
