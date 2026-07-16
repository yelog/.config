local M = {}

local prettier = { "prettier", stop_after_first = true }

function M.config()
  return {
    formatters_by_ft = {
      javascript = prettier,
      javascriptreact = prettier,
      typescript = prettier,
      typescriptreact = prettier,
      vue = prettier,
      markdown = prettier,
      lua = { "stylua" },
      rust = { "rustfmt", lsp_format = "fallback" },
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    notify_on_error = true,
    notify_no_formatters = true,
  }
end

function M.format(opts)
  opts = opts or {}
  local markdown_code_block = opts.markdown_code_block
  if vim.bo[opts.bufnr or 0].filetype == "markdown" and markdown_code_block and markdown_code_block() then
    return
  end

  local format_opts = vim.tbl_extend("force", {
    bufnr = opts.bufnr or 0,
    async = opts.async ~= false,
    timeout_ms = opts.timeout_ms or 3000,
    lsp_format = "fallback",
  }, opts)
  format_opts.markdown_code_block = nil
  require("conform").format(format_opts)
end

return M
