local M = {}

local shutdown_runtimes = setmetatable({}, { __mode = "k" })
local spinner_frames = { "◐", "◓", "◑", "◒" }
local current_shutdown_status

local function default_render_shutdown_status(_, status)
  current_shutdown_status = status
  pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "ServicesStatusChanged", modeline = false })
  pcall(vim.cmd, "redrawstatus")
end

function M.shutdown_status()
  return current_shutdown_status
end

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

local function pending_count(module, done)
  if module and type(module.shutdown_pending_count) == "function" then
    local ok, count = pcall(module.shutdown_pending_count, module)
    if ok and type(count) == "number" then return math.max(0, count) end
  end
  return done and 0 or 1
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

  local now = opts.now or function() return vim.uv.hrtime() / 1000000 end
  local render_status = opts.render_shutdown_status or default_render_shutdown_status
  local started_at = now()
  local last_render_at = -120
  local feedback_shown = false
  local function render(message, status)
    feedback_shown = feedback_shown or message ~= nil
    pcall(render_status, message, status)
  end

  local debug = java_debug(opts)
  call(runtime, "begin_shutdown")
  call(debug, "begin_shutdown")

  local runtime_done = complete(runtime)
  local debug_done = complete(debug)
  local total_pending = pending_count(runtime, runtime_done) + pending_count(debug, debug_done)
  local function render_pending(force)
    local elapsed = now() - started_at
    if not force and elapsed - last_render_at < 120 then return end
    last_render_at = elapsed
    local pending = pending_count(runtime, runtime_done) + pending_count(debug, debug_done)
    if pending == 0 then return end
    local frame = spinner_frames[(math.floor(elapsed / 120) % #spinner_frames) + 1]
    local message = string.format("%s 正在关闭服务 %d/%d · %.1fs", frame, pending, total_pending, elapsed / 1000)
    render(message, { phase = "closing", text = message })
  end

  if not runtime_done or not debug_done then
    render_pending(true)
    local wait = opts.wait or vim.wait
    pcall(wait, opts.grace_ms or 3000, function()
      runtime_done = complete(runtime)
      debug_done = complete(debug)
      if not runtime_done or not debug_done then render_pending(false) end
      return runtime_done and debug_done
    end, 20)
  end

  if not runtime_done or not debug_done then
    render("正在强制关闭剩余服务…", { phase = "force", text = "! 正在强制关闭剩余服务" })
  end
  if not runtime_done then call(runtime, "force_shutdown") end
  if not debug_done then call(debug, "force_shutdown") end
  runtime_done = complete(runtime)
  debug_done = complete(debug)
  if feedback_shown then render(nil, nil) end
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
