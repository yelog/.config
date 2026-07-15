local M = {}

local shutdown_runtimes = setmetatable({}, { __mode = "k" })

local function call(module, method)
  if not module or type(module[method]) ~= "function" then return true end
  local ok, result = pcall(module[method], module)
  return ok and result ~= false
end

local function complete(module)
  if not module or type(module.is_shutdown_complete) ~= "function" then return true end
  local ok, result = pcall(module.is_shutdown_complete, module)
  return ok and result == true
end

local function java_debug(opts)
  if opts.java_debug ~= nil then return opts.java_debug end
  local ok, module = pcall(require, "custom.java_debug")
  return ok and module or nil
end

function M.shutdown(runtime, opts)
  opts = opts or {}
  if not runtime or shutdown_runtimes[runtime] then return false end
  shutdown_runtimes[runtime] = true

  local debug = java_debug(opts)
  call(runtime, "begin_shutdown")
  call(debug, "begin_shutdown")

  local runtime_done = complete(runtime)
  local debug_done = complete(debug)
  if not runtime_done or not debug_done then
    local wait = opts.wait or vim.wait
    pcall(wait, opts.grace_ms or 3000, function()
      runtime_done = complete(runtime)
      debug_done = complete(debug)
      return runtime_done and debug_done
    end, 20)
  end

  if not runtime_done then call(runtime, "force_shutdown") end
  if not debug_done then call(debug, "force_shutdown") end
  runtime_done = complete(runtime)
  debug_done = complete(debug)
  return runtime_done and debug_done
end

function M.setup(runtime, opts)
  local group = vim.api.nvim_create_augroup("ServicesLifecycle", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.shutdown(runtime, opts)
    end,
  })
  return runtime
end

return M
