local service_state = require("overseer.service_state")

local function touch(task)
  local ok, task_list = pcall(require, "overseer.task_list")
  if ok then task_list.touch(task) end
end

local function is_maven_command(command)
  if type(command) ~= "table" or not command[1] then return false end
  local executable = vim.fs.basename(tostring(command[1]))
  return executable == "mvn" or executable == "mvnw" or executable == "mvn.cmd"
end

-- Check if command is bash -c wrapping Maven commands
local function is_bash_maven_command(command)
  if type(command) ~= "table" or #command < 3 then return false end
  if vim.fs.basename(tostring(command[1])) ~= "bash" then return false end
  if command[2] ~= "-c" then return false end
  local cmd_str = tostring(command[3] or "")
  return cmd_str:match("mvn ") ~= nil
end

local function apply_maven_profile(task)
  if is_maven_command(task.cmd) then
    -- Direct Maven command
    local command = {}
    local index = 1
    while index <= #task.cmd do
      local argument = tostring(task.cmd[index])
      if argument == "-P" then
        index = index + 2
      elseif argument:match("^%-P.+") then
        index = index + 1
      else
        table.insert(command, task.cmd[index])
        index = index + 1
      end
    end

    local profile = service_state.get_profile(task.metadata.project_root)
    if profile and profile ~= "" then
      table.insert(command, 2, "-P" .. profile)
    end
    task.cmd = command
    task.metadata.profile = profile
  elseif is_bash_maven_command(task.cmd) then
    -- bash -c "mvn ... && mvn ..." - modify the command string
    local profile = service_state.get_profile(task.metadata.project_root)
    if profile and profile ~= "" then
      local cmd_str = task.cmd[3]
      -- Add -Pprofile after each mvn command
      cmd_str = cmd_str:gsub("mvn%s+", "mvn -P" .. profile .. " ", 2)
      task.cmd[3] = cmd_str
    end
    task.metadata.profile = profile
  end
end

local function parse_server_line(line)
  local supported = false
  for _, server in ipairs({ "Tomcat", "Netty", "Jetty", "Undertow" }) do
    if line:find(server .. " started on port", 1, true) then
      supported = true
      break
    end
  end
  if not supported then return nil end

  local port = line:match("started on port%(s%):%s*(%d+)")
    or line:match("started on port%(s%)%s+(%d+)")
    or line:match("started on port:?%s*(%d+)")
  if not port then return nil end

  local protocol = line:match("%((https?)") or "http"
  local context_path = line:match("context path%s+['\"]([^'\"]*)['\"]") or ""
  if context_path == "/" then
    context_path = ""
  elseif context_path ~= "" and context_path:sub(1, 1) ~= "/" then
    context_path = "/" .. context_path
  end

  port = tonumber(port)
  return {
    port = port,
    protocol = protocol,
    context_path = context_path,
    url = string.format("%s://localhost:%d%s", protocol, port, context_path),
  }
end

return {
  desc = "Spring Boot profile and runtime metadata",
  editable = false,
  serializable = true,
  constructor = function()
    return {
      on_init = function(self, task)
        task.metadata = task.metadata or {}
        task.metadata.springboot = true
        task.metadata.ready = false
      end,

      on_pre_start = function(self, task)
        apply_maven_profile(task)
      end,

      on_start = function(self, task)
        task.metadata.ready = false
        task.metadata.port = nil
        task.metadata.protocol = nil
        task.metadata.context_path = nil
        task.metadata.url = nil
        touch(task)
      end,

      on_output_lines = function(self, task, lines)
        local changed = false
        for _, line in ipairs(lines) do
          local server = parse_server_line(line)
          -- A second embedded server is commonly the management/actuator port.
          if server and not task.metadata.port then
            for key, value in pairs(server) do
              task.metadata[key] = value
            end
            changed = true
          end

          if line:match("Started%s+[%w_.$]+%s+in%s+[%d%.]+%s+seconds") then
            task.metadata.ready = true
            changed = true
          end
        end
        if changed then touch(task) end
      end,

      on_reset = function(self, task)
        task.metadata.ready = false
        task.metadata.port = nil
        task.metadata.url = nil
        touch(task)
      end,

      on_exit = function(self, task)
        task.metadata.ready = false
        touch(task)
      end,
    }
  end,
}
