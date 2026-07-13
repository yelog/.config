local M = {}

-- 服务定义配置
-- 每个服务包含: name, cmd, cwd, env, group, health_check, auto_restart
-- 可以通过项目级 .services.lua 覆盖或追加

-- 默认示例服务定义（按需修改）
M.defaults = {
  -- 示例: 前端开发服务器
  -- {
  --   name = "frontend",
  --   cmd = { "npm", "run", "dev" },
  --   cwd = vim.fn.expand("~/workspace/my-project/frontend"),
  --   group = "app",
  --   auto_restart = true,
  -- },
  -- 示例: 后端 API
  -- {
  --   name = "backend-api",
  --   cmd = { "npm", "run", "start:dev" },
  --   cwd = vim.fn.expand("~/workspace/my-project/backend"),
  --   group = "app",
  --   auto_restart = true,
  -- },
  -- 示例: Redis
  -- {
  --   name = "redis",
  --   cmd = { "redis-server" },
  --   group = "infra",
  -- },
  -- 示例: Docker Compose
  -- {
  --   name = "docker-infra",
  --   cmd = { "docker", "compose", "up" },
  --   cwd = vim.fn.expand("~/workspace/my-project"),
  --   group = "infra",
  -- },
}

-- 项目级配置文件名
M.project_config_name = ".services.lua"

function M.load()
  local services = vim.deepcopy(M.defaults)

  -- 尝试加载项目级配置
  local config_dir = vim.fn.stdpath("config")
  local project_config = vim.fn.findfile(M.project_config_name, ".;")
  if project_config ~= "" then
    local ok, project_services = pcall(dofile, project_config)
    if ok and type(project_services) == "table" then
      for _, svc in ipairs(project_services) do
        table.insert(services, svc)
      end
    end
  end

  return services
end

function M.save(services)
  local config_dir = vim.fn.stdpath("config")
  local path = config_dir .. "/lua/custom/services.lua"
  -- 仅更新 defaults 表
  local lines = {
    "local M = {}",
    "",
    "M.defaults = {",
  }
  for _, svc in ipairs(services) do
    table.insert(lines, "  {")
    table.insert(lines, '    name = "' .. svc.name .. '",')
    if type(svc.cmd) == "table" then
      local cmd_parts = {}
      for _, c in ipairs(svc.cmd) do
        table.insert(cmd_parts, '"' .. c .. '"')
      end
      table.insert(lines, "    cmd = { " .. table.concat(cmd_parts, ", ") .. " },")
    else
      table.insert(lines, '    cmd = "' .. svc.cmd .. '",')
    end
    if svc.cwd then
      table.insert(lines, '    cwd = "' .. svc.cwd .. '",')
    end
    if svc.group then
      table.insert(lines, '    group = "' .. svc.group .. '",')
    end
    if svc.env then
      table.insert(lines, "    env = {")
      for k, v in pairs(svc.env) do
        table.insert(lines, '      ' .. k .. ' = "' .. v .. '",')
      end
      table.insert(lines, "    },")
    end
    if svc.auto_restart then
      table.insert(lines, "    auto_restart = true,")
    end
    if svc.health_check then
      table.insert(lines, '    health_check = "' .. svc.health_check .. '",')
    end
    table.insert(lines, "  },")
  end
  table.insert(lines, "}")
  table.insert(lines, "")
  table.insert(lines, "function M.load()")
  table.insert(lines, "  return vim.deepcopy(M.defaults)")
  table.insert(lines, "end")
  table.insert(lines, "")
  table.insert(lines, "return M")

  local file = io.open(path, "w")
  if file then
    file:write(table.concat(lines, "\n"))
    file:close()
  end
end

return M
