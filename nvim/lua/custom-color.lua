-->important
vim.cmd([[highlight ye_import1 cterm=bold guifg=#efdf00]])
vim.fn.matchadd("ye_import1", "\\v( |^)@<=!(!)@!")
vim.cmd([[highlight ye_import2 cterm=bold guifg=#fe5000]])
vim.fn.matchadd("ye_import2", "\\v( |^)@<=!!(!)@!")
vim.cmd([[highlight ye_import3 cterm=bold guifg=#e4002b]])
vim.fn.matchadd("ye_import3", "\\v( |^)@<=!!!(!)@!")

-- 在VimEnter事件中延迟执行颜色配置
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd([[highlight NeoTreeGitAdded guifg=#109900]])
    vim.cmd([[highlight NeoTreeGitModified guifg=#0099FF]])
    vim.cmd([[highlight NeoTreeGitDeleted guifg=#ff2222]])
    vim.cmd([[highlight GitSignsAdd guifg=#109900]])
    vim.cmd([[highlight GitSignsStagedAdd guifg=#109900]])
    vim.cmd([[highlight GitSignsChange guifg=#0099FF]])
    vim.cmd([[highlight GitSignsStagedChange guifg=#0099FF]])
    vim.cmd([[highlight GitSignsDelete guifg=#ff2222]])
    vim.cmd([[highlight GitSignsStagedDelete guifg=#ff2222]])
  end
})

vim.filetype.add({
  extension = {
    drawio = "xml"
  }
})

-- 今日日期高亮配置
-- 定义高亮样式
vim.cmd([[
  hi Today ctermfg=Green cterm=standout gui=standout
]])

-- 模块化封装
local M = {}
M.current_date = ""

-- 刷新高亮函数
function M.refresh_highlight()
  -- 检查当前缓冲区是否为 markdown 文件
  local filetype = vim.bo.filetype
  if filetype ~= 'markdown' then
    return
  end

  local today = os.date("%Y-%m-%d")

  if M.current_date ~= today then
    M.current_date = today
    -- 清除旧匹配并设置新匹配
    vim.cmd('call clearmatches()')
    vim.cmd(string.format('match Today /\\V%s/', today))
  end
end

-- 全局刷新函数（用于定时器）
function M.global_refresh()
  local today = os.date("%Y-%m-%d")

  if M.current_date ~= today then
    M.current_date = today

    -- 为所有 markdown 缓冲区刷新高亮
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        local buf_filetype = vim.api.nvim_buf_get_option(buf, 'filetype')
        if buf_filetype == 'markdown' then
          -- 找到显示该缓冲区的窗口并刷新
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == buf then
              local current_win = vim.api.nvim_get_current_win()
              vim.api.nvim_set_current_win(win)
              vim.cmd('call clearmatches()')
              vim.cmd(string.format('match Today /\\V%s/', today))
              vim.api.nvim_set_current_win(current_win)
              break
            end
          end
        end
      end
    end
  end
end

-- 创建 autocmd 组
local group = vim.api.nvim_create_augroup('TodayHighlight', { clear = true })

-- 文件类型检测时触发
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'markdown',
  callback = M.refresh_highlight,
})

-- 进入缓冲区时触发
vim.api.nvim_create_autocmd('BufEnter', {
  group = group,
  pattern = '*.md',
  callback = M.refresh_highlight,
})

-- 窗口进入时触发（处理分屏情况）
vim.api.nvim_create_autocmd('WinEnter', {
  group = group,
  pattern = '*',
  callback = function()
    if vim.bo.filetype == 'markdown' then
      M.refresh_highlight()
    end
  end,
})

-- 初始化
M.refresh_highlight()

-- 设置定时器，每分钟检查一次日期变化
local timer = vim.loop.new_timer()
if timer then
  timer:start(60000, 60000, vim.schedule_wrap(M.global_refresh))
end

-- 创建手动刷新命令
vim.api.nvim_create_user_command('RefreshDateHighlight', function()
  M.current_date = "" -- 强制更新
  M.global_refresh()
end, { desc = "手动更新今日日期高亮" })

-- 清理函数（可选，用于调试）
vim.api.nvim_create_user_command('ClearDateHighlight', function()
  vim.cmd('call clearmatches()')
end, { desc = "清除日期高亮" })

-- 导出模块（可选）
_G.date_highlight_module = M
