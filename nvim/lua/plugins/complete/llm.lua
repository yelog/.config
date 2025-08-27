return {
  "Kurama622/llm.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
  cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
  config = function()
    local tools = require("llm.tools")
    local function local_llm_streaming_handler(chunk, ctx, F)
      if not chunk then
        return ctx.assistant_output
      end
      local tail = chunk:sub(-1, -1)
      if tail:sub(1, 1) ~= "}" then
        ctx.line = ctx.line .. chunk
      else
        ctx.line = ctx.line .. chunk
        local status, data = pcall(vim.fn.json_decode, ctx.line)
        if not status or not data.message.content then
          return ctx.assistant_output
        end
        ctx.assistant_output = ctx.assistant_output .. data.message.content
        F.WriteContent(ctx.bufnr, ctx.winid, data.message.content)
        ctx.line = ""
      end
      return ctx.assistant_output
    end

    local function local_llm_parse_handler(chunk)
      local assistant_output = chunk.message.content
      return assistant_output
    end
    require("llm").setup({
      url = "https://api.githubcopilot.com/chat/completions",
      model = "gpt-4.1",
      api_type = "openai",
      app_handler = {
        Translate = {
          handler = tools.qa_handler,
          opts = {
            component_width = "60%",
            component_height = "50%",
            query = {
              title = " 󰊿 Trans ",
              hl = { link = "Define" },
            },
            input_box_opts = {
              size = "15%",
              win_options = {
                winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
              },
            },
            preview_box_opts = {
              size = "85%",
              win_options = {
                winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
              },
            },
          },
        },
        CommitMsg = {
          handler = tools.flexi_handler,
          prompt = function()
            -- Source: https://andrewian.dev/blog/ai-git-commits
            return string.format(
              [[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:

1. First line: conventional commit format (type: concise description) (remember to use semantic types like feat, fix, docs, style, refactor, perf, test, chore, etc.)
2. Optional bullet points if more context helps:
   - Keep the second line blank
   - Keep them short and direct
   - Focus on what changed
   - Always be terse
   - Don't overly explain
   - Drop any fluffy or formal language

Return ONLY the commit message - no introduction, no explanation, no quotes around it.

Examples:
feat: add user auth system

- Add JWT tokens for API auth
- Handle token refresh for long sessions

fix: resolve memory leak in worker pool

- Clean up idle connections
- Add timeout for stale workers

Simple change example:
fix: typo in README.md

Very important: Do not respond with any of the examples. Your message must be based off the diff that is about to be provided, with a little bit of styling informed by the recent commits you're about to see.

Based on this format, generate appropriate commit messages. Respond with message only. DO NOT format the message in Markdown code blocks, DO NOT use backticks:

```diff
%s
```
]],
              vim.fn.system("git diff --no-ext-diff --staged")
            )
          end,

          opts = {
            enter_flexible_window = true,
            apply_visual_selection = false,
            win_opts = {
              relative = "editor",
              position = "50%",
            },
            accept = {
              mapping = {
                mode = "n",
                keys = "<cr>",
              },
              action = function()
                local contents = vim.api.nvim_buf_get_lines(0, 0, -1, true)

                local cmd = string.format('!git commit -m "%s"', table.concat(contents, '" -m "'))
                cmd = (cmd:gsub(".", {
                  ["#"] = "\\#",
                }))

                vim.api.nvim_command(cmd)
                -- just for lazygit
                vim.schedule(function()
                  vim.api.nvim_command("LazyGit")
                end)
              end,
            },
          },
        },
        DocString = {
          prompt =
          [[ You are an AI programming assistant. You need to write a really good docstring that follows a best practice for the given language.

Your core tasks include:
- parameter and return types (if applicable).
- any errors that might be raised or returned, depending on the language.

You must:
- Place the generated docstring before the start of the code.
- Follow the format of examples carefully if the examples are provided.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of the Markdown code blocks.]],
          handler = tools.action_handler,
          opts = {
            only_display_diff = true,
            templates = {
              lua = [[- For the Lua language, you should use the LDoc style.
- Start all comment lines with "---".
]],
            },
          },
        },
      }
    })
  end,
  keys = {
    { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
  },
}
