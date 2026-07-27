local M = {}

function M.summary(services, shutdown)
  if shutdown and shutdown.text then
    local kind = shutdown.phase == "force" and "force" or "closing"
    return { text = shutdown.text, kind = kind }
  end
  if #services == 0 then return nil end

  local starting, running, stopping, failed = 0, 0, 0, false
  for _, service in ipairs(services) do
    if service.status == "STARTING" or (service.status == "RUNNING" and service.metadata and service.metadata.ready == false) then
      starting = starting + 1
    elseif service.status == "RUNNING" or service.status == "DEBUGGING" then
      running = running + 1
    elseif service.status == "STOPPING" then
      stopping = stopping + 1
    elseif service.status == "FAILED" then
      failed = true
    end
  end

  if stopping > 0 then return { text = "◒ 关闭中 " .. stopping, kind = "stopping" } end
  if starting > 0 then return { text = "◔ 启动中 " .. starting, kind = "starting" } end
  if failed then return { text = "× 服务启动失败", kind = "failed" } end
  if running > 0 then return { text = "● 运行中 " .. running, kind = "running" } end
  return { text = "○ 服务未运行", kind = "idle" }
end

return M
