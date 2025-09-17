return {
  "lewis6991/gitsigns.nvim", -- https://github.com/lewis6991/gitsigns.nvim
  config = function()
    require('gitsigns').setup {
      signs                        = {
        add          = { text = '▍' },
        change       = { text = '▍' },
        delete       = { text = '▶' },
        topdelete    = { text = '▶' },
        changedelete = { text = '▶' },
        untracked    = { text = '▍' },
      },
      signs_staged                 = {
        add          = { text = '▍' },
        change       = { text = '▍' },
        delete       = { text = '▶' },
        topdelete    = { text = '▶' },
        changedelete = { text = '▶' },
        untracked    = { text = '▍' },
      },
      signcolumn                   = true,  -- Toggle with `:Gitsigns toggle_signs`
      numhl                        = false, -- Toggle with `:Gitsigns toggle_numhl`
      linehl                       = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff                    = false, -- Toggle with `:Gitsigns toggle_word_diff`
      watch_gitdir                 = {
        follow_files = true
      },
      auto_attach                  = true,
      attach_to_untracked          = false,
      current_line_blame           = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts      = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 100,
        ignore_whitespace = false,
        virt_text_priority = 50,
      },
      current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
      sign_priority                = 6,
      update_debounce              = 100,
      status_formatter             = nil,   -- Use default
      max_file_length              = 40000, -- Disable if file is longer than this (in lines)
      preview_config               = {
        -- Options passed to nvim_open_win
        border = 'single',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1
      },
      on_attach                    = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', '<leader>gj', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = 'Next Hunk' })

        map('n', '<leader>gk', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = 'Previous Hunk' })

        -- Actions
        map('n', '<leader>gs', gs.stage_hunk, { desc = 'Git Stage Hunk' })
        map('n', '<leader>gr', gs.reset_hunk, { desc = 'Git Reset Hunk' })
        map('v', '<leader>gs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
          { desc = 'Git Stage Hunk' })
        map('v', '<leader>gr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
          { desc = 'Git Reset Hunk' })
        map('n', '<leader>gS', gs.stage_buffer, { desc = 'Git Stage Buffer' })
        map('n', '<leader>gu', gs.undo_stage_hunk, { desc = 'Git Undo Stage Hunk' })
        map('n', '<leader>gR', gs.reset_buffer, { desc = 'Git Reset Buffer' })
        map('n', '<leader>gp', gs.preview_hunk, { desc = 'Git Preview Hunk' })
        -- map('n', '<leader>gb', function() gs.blame_line { full = true } end, { desc = 'Git Blame Line' })
        map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'Git Toggle Current Line Blame' })
        map('n', '<leader>gd', gs.diffthis, { desc = 'Git Diff This' })
        map('n', '<leader>gD', function() gs.diffthis('~') end, { desc = 'Git Diff This ~' })
        map('n', '<leader>td', gs.toggle_deleted, { desc = 'Git Toggle Deleted' })
        map('n', '<leader>gb', function()
          vim.cmd('Gitsigns blame')
        end, { desc = 'Git Toggle Deleted' })

        -- Text object
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'Git Select Hunk' })

        -- auto add staging area
        -- vim.api.nvim_create_autocmd('BufWritePost', {
        --   buffer = bufnr,
        --   callback = function()
        --     gs.stage_hunk()
        --   end
        -- })
        -- -- 自动暂存更改/新增/删除
        -- vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
        --   buffer = bufnr,
        --   callback = function()
        --     vim.schedule(function()
        --       -- 暂存所有更改的 hunk
        --       gs.stage_hunk()
        --     end)
        --   end,
        -- })
        -- 自动将修改、删除、添加的文件添加到 Git 暂存区
        -- 2025-02-05 暂时屏蔽, 会导致 prev_hunk 无法正常工作
        -- vim.api.nvim_create_autocmd({ "BufWritePost", "BufDelete", "BufNewFile" }, {
        --   pattern = "*",                      -- 作用于所有文件
        --   callback = function()
        --     local file = vim.fn.expand('%:p') -- 获取当前文件的完整路径
        --     local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
        --
        --     if vim.v.shell_error == 0 and file:find(git_root, 1, true) == 1 then
        --       -- 当前文件在 Git 仓库内
        --       vim.fn.system('git add ' .. vim.fn.shellescape(file))
        --       print("✅ Auto git add: " .. file)
        --     end
        --   end,
        -- })
      end,
    }
  end
}
