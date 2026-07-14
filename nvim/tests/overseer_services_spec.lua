local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error((message or "values differ")
      .. "\nexpected: " .. vim.inspect(expected)
      .. "\nactual:   " .. vim.inspect(actual))
  end
end

local temp_dir = vim.fn.tempname()
vim.fn.mkdir(temp_dir, "p")

local state = require("overseer.service_state")
local state_path = temp_dir .. "/spring-services.json"
state.setup({ path = state_path })

assert_equal(nil, state.get_profile("/project/a"), "missing profile should be nil")
assert(state.set_profile("/project/a", "dev"), "profile write should succeed")
assert_equal("dev", state.get_profile("/project/a"), "profile should be cached")
assert_equal(nil, state.get_profile("/project/b"), "profiles should be isolated by project")

local external_state = vim.json.decode(table.concat(vim.fn.readfile(state_path), "\n"))
external_state.projects["/project/b"] = { profile = "qa" }
vim.fn.writefile({ vim.json.encode(external_state) }, state_path)
assert(state.set_profile("/project/a", "prod"), "write should merge with the latest disk state")
assert_equal("qa", state.get_profile("/project/b"), "external project updates should not be overwritten")

state.setup({ path = state_path })
assert_equal("prod", state.get_profile("/project/a"), "profile should survive a reload")
assert(state.set_profile("/project/a", nil), "profile removal should succeed")
assert_equal(nil, state.get_profile("/project/a"), "removed profile should be nil")

vim.fn.writefile({ "not-json" }, state_path)
state.setup({ path = state_path })
assert_equal(nil, state.get_profile("/project/a"), "invalid JSON should fall back to empty state")

vim.fn.writefile({ '{"projects":{"/project/a":{"profile":42}}}' }, state_path)
state.setup({ path = state_path })
assert_equal(nil, state.get_profile("/project/a"), "non-string profiles should be ignored")

local blocker = temp_dir .. "/not-a-directory"
vim.fn.writefile({ "blocker" }, blocker)
state.setup({ path = blocker .. "/state.json" })
assert_equal(false, state.set_profile("/project/a", "dev"), "failed writes should return false")
assert_equal(nil, state.get_profile("/project/a"), "failed writes should not leak into memory")

local project_root = temp_dir .. "/project"
vim.fn.mkdir(project_root, "p")
vim.fn.writefile({
  "<project>",
  "  <profiles>",
  "    <!-- ignored -->",
  "    <profile><activation><activeByDefault>true</activeByDefault></activation><id> local </id></profile>",
  "    <profile>",
  "      <id>dev</id>",
  "    </profile>",
  "    <profile><id>dev</id></profile>",
  "  </profiles>",
  "</project>",
}, project_root .. "/pom.xml")
assert_equal({ "dev", "local" }, state.parse_maven_profiles(project_root), "profiles should be unique and sorted")

state.setup({ path = state_path })
assert(state.set_profile(project_root, "dev"), "component profile should persist")

local component_definition = require("overseer.component.service.springboot")
local component = component_definition.constructor({})
local task = {
  cmd = { "mvn", "-Pold", "-pl", "app", "spring-boot:run" },
  metadata = { project_root = project_root },
}

component.on_init(component, task)
assert_equal(true, task.metadata.springboot, "component should identify Spring Boot tasks")
component.on_pre_start(component, task)
assert_equal({ "mvn", "-Pdev", "-pl", "app", "spring-boot:run" }, task.cmd, "profile should be replaced before start")

state.set_profile(project_root, "prod")
component.on_pre_start(component, task)
assert_equal({ "mvn", "-Pprod", "-pl", "app", "spring-boot:run" }, task.cmd, "new profile should replace the old profile")

component.on_start(component, task)
assert_equal(false, task.metadata.ready, "service should start in the starting state")
component.on_output_lines(component, task, {
  "Tomcat started on port 8080 (http) with context path '/api'",
})
assert_equal(8080, task.metadata.port, "Tomcat port should be detected")
assert_equal("http://localhost:8080/api", task.metadata.url, "Tomcat URL should include context path")
assert_equal(false, task.metadata.ready, "port detection alone should not mark startup complete")

component.on_output_lines(component, task, { "Started DemoApplication in 2.41 seconds" })
assert_equal(true, task.metadata.ready, "Spring Started message should mark service ready")
component.on_output_lines(component, task, { "Tomcat started on port 9091 (http) with context path '/actuator'" })
assert_equal(8080, task.metadata.port, "management port should not replace the application port")
component.on_exit(component, task)
assert_equal(false, task.metadata.ready, "service should not remain ready after exit")

local server_cases = {
  { "Netty started on port 9090 (https)", 9090, "https://localhost:9090" },
  { "Jetty started on port 7070 (http/1.1) with context path '/'", 7070, "http://localhost:7070" },
  { "Undertow started on port(s) 6060 (http)", 6060, "http://localhost:6060" },
  { "Tomcat started on port(s): 5050 (http) with context path ''", 5050, "http://localhost:5050" },
}

for _, case in ipairs(server_cases) do
  component.on_start(component, task)
  component.on_output_lines(component, task, { case[1] })
  assert_equal(case[2], task.metadata.port, "server port should be detected from: " .. case[1])
  assert_equal(case[3], task.metadata.url, "server URL should be detected from: " .. case[1])
end

local multi_root = temp_dir .. "/spring-cloud"
local module_root = multi_root .. "/order-service"
local source_dir = module_root .. "/src/main/java/com/example/order"
vim.fn.mkdir(multi_root .. "/.git", "p")
vim.fn.mkdir(source_dir, "p")
vim.fn.writefile({
  "<project>",
  "  <dependencies><dependency><artifactId>spring-boot-starter</artifactId></dependency></dependencies>",
  "</project>",
}, multi_root .. "/pom.xml")
vim.fn.writefile({ "<project><artifactId>order-service</artifactId></project>" }, module_root .. "/pom.xml")
vim.fn.writefile({
  "package com.example.order;",
  "@SpringBootApplication",
  "public class OrderApplication {}",
}, source_dir .. "/OrderApplication.java")

local templates = require("overseer.template.springboot").generator({ dir = module_root })
assert_equal(1, #templates, "one Spring service should be discovered")
local definition = templates[1].builder({})
assert_equal("com.example.order.OrderApplication", definition.metadata.main_class,
  "service metadata should expose the fully qualified main class")
assert_equal(module_root, definition.metadata.module_root, "service metadata should expose its Maven module root")
assert_equal("order-service", definition.metadata.project_name, "service metadata should expose its Maven project name")
assert_equal(module_root .. "::com.example.order.OrderApplication", definition.metadata.task_key,
  "service identity should include its Maven module")
assert_equal(nil, definition.metadata.class, "obsolete class metadata should not be emitted")

vim.fn.delete(temp_dir, "rf")
print("overseer-services-tests: ok")
