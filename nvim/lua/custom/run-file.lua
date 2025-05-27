-- 检查光标是否在 http 块内
local function is_cursor_in_http_block()
  local api = vim.api
  local bufnr = api.nvim_get_current_buf()
  local cursor = api.nvim_win_get_cursor(0)
  local cur_line = cursor[1]

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local start_line = nil
  local end_line = nil

  -- 向上查找 ```http
  for i = cur_line - 1, 1, -1 do
    local line = lines[i]
    if line:match("^```http%s*$") then
      start_line = i
      break
    end
  end

  -- 向下查找 ```
  for i = cur_line, #lines do
    local line = lines[i]
    if line:match("^```%s*$") then
      end_line = i
      break
    end
  end

  if start_line and end_line and start_line < cur_line and cur_line < end_line then
    return true
  else
    return false
  end
end

-- 根据不同的文件类型执行不同的命令
function ExecuteFileTypeCommands()
  local filetype = vim.bo.filetype
  -- 获取文件后缀
  local extension = vim.fn.expand('%:e')
  local modeInfo = vim.api.nvim_get_mode()
  local mode = modeInfo.mode
  local firstLine = vim.fn.getline(1)
  -- local content

  -- if mode == "V" or mode == "CTRL-V" or mode == "\22" then
  --   content = table.concat(getVisualSelection(), "\n")
  -- else
  --   content = '%'
  -- end
  -- print(content)

  -- 声明变量 content, 如果是normal模式, 赋值 %, 如果是visual模式, 赋值选中的内容
  if filetype == 'javascript' and string.find(tostring(firstLine), "k6/http") then
    vim.cmd('set splitright')
    vim.cmd('vsp')
    vim.cmd('term k6 run %')
    -- 修复报错 connection reset by peer, 但是效果不明显
    -- docker run --rm -i grafana/k6 run - <script.js
    -- vim.cmd('term docker run --rm -i grafana/k6 run - < %')
  elseif filetype == 'markdown' then
    if is_cursor_in_http_block() then
      require('kulala').run()
    else
      -- vim.cmd('InstantMarkdownPreview')
      vim.cmd('MarkdownPreview')
    end
  elseif filetype == 'http' then
    -- vim.cmd('Rest run')
    require('kulala').run()
  elseif filetype == 'lua' then
    vim.cmd('set splitright')
    vim.cmd('vsp')
    vim.cmd('term lua %')
  elseif filetype == 'javascript' then
    vim.cmd('set splitright')
    vim.cmd('vsp')
    vim.cmd('term node %')
  elseif filetype == 'html' then
    vim.cmd('!open "%"')
  elseif filetype == 'sh' then
    vim.cmd('set splitright')
    vim.cmd('vsp')
    vim.cmd('term sh %')
  elseif filetype == 'python' then
    vim.cmd('set splitright')
    vim.cmd('vsp')
    vim.cmd('term python3 %')
  elseif filetype == 'rust' then
    vim.cmd('set splitright')
    vim.cmd('vsp')
    vim.cmd('term rustc % && ' .. vim.fn.expand('%:p:r'))
  elseif extension == 'drawio' then
    vim.cmd('!open "%"')
  else
    -- 添加其他文件类型的处理，如果需要
  end
end

-- 打印 table
function print_r(t)
  local print_r_cache = {}
  local function sub_print_r(t, indent)
    if (print_r_cache[tostring(t)]) then
      print(indent .. "*" .. tostring(t))
    else
      print_r_cache[tostring(t)] = true
      if (type(t) == "table") then
        for pos, val in pairs(t) do
          if (type(val) == "table") then
            print(indent .. "[" .. pos .. "] => " .. tostring(t) .. " {")
            sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
            print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
          elseif (type(val) == "string") then
            print(indent .. "[" .. pos .. '] => "' .. val .. '"')
          else
            print(indent .. "[" .. pos .. "] => " .. tostring(val))
          end
        end
      else
        print(indent .. tostring(t))
      end
    end
  end
  if (type(t) == "table") then
    print(tostring(t) .. " {")
    sub_print_r(t, "  ")
    print("}")
  else
    sub_print_r(t, "  ")
  end
  print()
end

-- 获取选中的内容
function getVisualSelection()
  local modeInfo = vim.api.nvim_get_mode()
  local mode = modeInfo.mode

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cline, ccol = cursor[1], cursor[2]
  local vline, vcol = vim.fn.line('v'), vim.fn.col('v')

  local sline, scol
  local eline, ecol
  if cline == vline then
    if ccol <= vcol then
      sline, scol = cline, ccol
      eline, ecol = vline, vcol
      scol = scol + 1
    else
      sline, scol = vline, vcol
      eline, ecol = cline, ccol
      ecol = ecol + 1
    end
  elseif cline < vline then
    sline, scol = cline, ccol
    eline, ecol = vline, vcol
    scol = scol + 1
  else
    sline, scol = vline, vcol
    eline, ecol = cline, ccol
    ecol = ecol + 1
  end

  if mode == "V" or mode == "CTRL-V" or mode == "\22" then
    scol = 1
    ecol = nil
  end

  local lines = vim.api.get_lines(0, sline - 1, eline, 0)
  if #lines == 0 then return end

  local startText, endText
  if #lines == 1 then
    startText = string.sub(lines[1], scol, ecol)
  else
    startText = string.sub(lines[1], scol)
    endText = string.sub(lines[#lines], 1, ecol)
  end

  local selection = { startText }
  if #lines > 2 then
    vim.list_extend(selection, vim.list_slice(lines, 2, #lines - 1))
  end
  table.insert(selection, endText)

  return selection
end

-- 创建键盘映射，绑定在Normal模式下的R键
vim.api.nvim_set_keymap('n', 'R', '<cmd>lua ExecuteFileTypeCommands()<cr>', { noremap = true, silent = true })
-- 创建键盘映射，绑定在Visual模式下的R键
-- vim.api.nvim_set_keymap('v', 'R', '<cmd>lua ExecuteFileTypeCommands()<cr>', { noremap = true, silent = true })
-- vim.api.nvim_create_user_command('getvv', print_visual_selection, { range = true })
-- vim.api.nvim_set_keymap('v', 'R', '<cmd>lua print_r(vim.fn.getpos("v"))<cr>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('v', 'R', '<cmd>lua print_r(getVisualSelection())<cr>', { noremap = true, silent = true })
