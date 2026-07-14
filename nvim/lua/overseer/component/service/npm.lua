local function touch(task)
  local ok, task_list = pcall(require, "overseer.task_list")
  if ok then task_list.touch(task) end
end

-- Parse Vite output: "ready in X ms" and "Local: http://localhost:5174/"
local function parse_vite_line(line)
  -- Match "VITE v8.0.0 ready in 3204 ms" or similar
  if line:match("ready in %d+ ms") then
    return { ready = true }
  end

  -- Match "Local: http://localhost:5174/" or "➜  Local:   http://localhost:5174/"
  local port = line:match("Local:%s+https?://localhost:(%d+)")
  if port then
    return { port = tonumber(port) }
  end

  return nil
end

-- Parse Next.js output: "ready - started server on 0.0.0.0:3000, url: http://localhost:3000"
local function parse_nextjs_line(line)
  if line:match("ready %- started server") then
    local port = line:match("on%s+[%d%.]+:(%d+)")
    return { ready = true, port = port and tonumber(port) or nil }
  end
  return nil
end

-- Parse webpack-dev-server output: "Project is running at http://localhost:8080/"
local function parse_webpack_line(line)
  if line:match("Project is running at") or line:match("Local:%s+http://localhost:") then
    local port = line:match("http://localhost:(%d+)")
    if port then
      return { ready = true, port = tonumber(port) }
    end
  end
  return nil
end

-- Parse generic "listening on port XXXX" patterns
local function parse_generic_line(line)
  -- "Server running at http://localhost:3000"
  -- "Listening on port 3000"
  -- "App listening on port 3000"
  if line:match("[Ll]istening on port%s+(%d+)") or
     line:match("[Ss]erver running at%s+https?://localhost:(%d+)") or
     line:match("[Aa]pp listening on port%s+(%d+)") then
    local port = line:match("(%d+)")
    if port then
      return { ready = true, port = tonumber(port) }
    end
  end
  return nil
end

return {
  desc = "Detect npm/frontend service ready state and port",
  editable = false,
  serializable = true,
  constructor = function()
    return {
      on_init = function(self, task)
        task.metadata = task.metadata or {}
        task.metadata.ready = false
      end,

      on_start = function(self, task)
        task.metadata.ready = false
        task.metadata.port = nil
        task.metadata.url = nil
        touch(task)
      end,

      on_output_lines = function(self, task, lines)
        local changed = false
        for _, line in ipairs(lines) do
          local result = parse_vite_line(line)
            or parse_nextjs_line(line)
            or parse_webpack_line(line)
            or parse_generic_line(line)

          if result then
            if result.ready and not task.metadata.ready then
              task.metadata.ready = true
              changed = true
            end
            if result.port and not task.metadata.port then
              task.metadata.port = result.port
              task.metadata.url = string.format("http://localhost:%d", result.port)
              changed = true
            end
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
