local M = {}
local generation = 0
local warned = {}

function M.setup(languages)
  generation = generation + 1
  local current_generation = generation
  local supported = {}
  for _, language in ipairs(languages) do
    supported[language] = true
  end

  local install_dir = vim.fn.stdpath("data") .. "/site"
  local function prioritize_install_dir()
    vim.opt.runtimepath:remove(install_dir)
    vim.opt.runtimepath:prepend(install_dir)
  end
  prioritize_install_dir()

  for filetype, language in pairs({ sh = "bash", javascriptreact = "javascript" }) do
    if vim.treesitter.language.get_lang(filetype) == filetype then
      vim.treesitter.language.register(language, filetype)
    end
  end

  local installing = true
  local function start(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) or vim.bo[bufnr].buftype ~= "" then
      return
    end
    local language = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
    if not supported[language] then
      return
    end
    if vim.opt.runtimepath:get()[1] ~= install_dir then
      prioritize_install_dir()
    end

    local highlighter = vim.treesitter.highlighter.active[bufnr]
    if highlighter and highlighter.tree:lang() == language then
      return
    end

    local ok, err = pcall(function()
      local available, reason = vim.treesitter.language.add(language)
      assert(available, reason)
      for _, name in ipairs({ "injections", "highlights" }) do
        vim.treesitter.query.get:clear(language, name)
      end
      vim.treesitter.query.get(language, "injections")
      assert(vim.treesitter.query.get(language, "highlights"), 'No highlight query for language "' .. language .. '"')
      if highlighter then
        vim.treesitter.stop(bufnr)
      end
      vim.treesitter.start(bufnr, language)
    end)
    if not ok then
      vim.treesitter.stop(bufnr)
      local key = language .. ":" .. tostring(err):gsub("buffer %d+", "buffer")
      if not installing and not warned[key] then
        warned[key] = true
        vim.notify(
          ("Tree-sitter (%s): %s\nRetrying on buffer entry; use :TSUpdate %s or :TSLog to diagnose."):format(
            language,
            err,
            language
          ),
          vim.log.levels.WARN
        )
      end
    end
  end

  local function start_loaded_buffers()
    if generation ~= current_generation then
      return
    end
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      start(bufnr)
    end
  end

  local group = vim.api.nvim_create_augroup("custom_treesitter_startup", { clear = true })
  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    group = group,
    callback = function(args)
      start(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "TSUpdate",
    callback = function()
      vim.schedule(start_loaded_buffers)
    end,
  })

  require("nvim-treesitter").install(languages):await(vim.schedule_wrap(function()
    if generation ~= current_generation then
      return
    end
    installing = false
    start_loaded_buffers()
  end))
  start_loaded_buffers()
end

return M
