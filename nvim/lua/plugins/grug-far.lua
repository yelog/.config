return {
  "MagicDuck/grug-far.nvim",
  config = function()
    local grug_far = require("grug-far")
    grug_far.setup({
      visualSelectionUsage = "prefill-search",
      engines = {
        ripgrep = {
          defaults = {
            flags = "--fixed-strings",
          },
        },
      },
    })

    grug_far._createWindow = function(context)
      context.prevWin = vim.api.nvim_get_current_win()
      local prev_buf = vim.api.nvim_win_get_buf(context.prevWin)
      context.prevBufName = vim.api.nvim_buf_get_name(prev_buf)
      context.prevBufFiletype = vim.bo[prev_buf].filetype

      context.snacks_win = Snacks.win({
        style = "float",
        border = "rounded",
        title = " Find & Replace ",
        fixbuf = false,
      })
      context.initialWin = context.snacks_win.win
      vim.api.nvim_set_current_win(context.initialWin)
      return context.initialWin
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("grug_far_keymaps", { clear = true }),
      pattern = "grug-far",
      callback = function(args)
        local function toggle_flag(flag, name)
          return function()
            local enabled = select(1, require("grug-far").get_instance(args.buf):toggle_flags({ flag }))
            vim.notify("grug-far: " .. name .. (enabled and " enabled" or " disabled"))
          end
        end

        vim.keymap.set("n", "<localleader>f", toggle_flag("--fixed-strings", "literal matching"), {
          buffer = args.buf,
          desc = "Toggle literal/regex matching",
        })
        vim.keymap.set("n", "<localleader>i", toggle_flag("--ignore-case", "case-insensitive matching"), {
          buffer = args.buf,
          desc = "Toggle case-insensitive matching",
        })
      end,
    })

    vim.keymap.set({ "n", "x" }, "<D-S-R>", function()
      require("grug-far").open()
    end, { desc = "Find and replace in project" })
  end,
}
