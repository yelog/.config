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
local project_root = temp_dir .. "/project"
local source_dir = project_root .. "/src/main/java/com/example/order"
vim.fn.mkdir(project_root .. "/.git", "p")
vim.fn.mkdir(source_dir, "p")
vim.fn.writefile({ "<project><artifactId>orders</artifactId></project>" }, project_root .. "/pom.xml")
vim.fn.writefile({
  "package com.example.order;",
  "@SpringBootApplication",
  "public class OrderApplication {}",
}, source_dir .. "/OrderApplication.java")

local springboot = require("services.providers.springboot")
local spring_definitions = springboot.discover({ dir = source_dir })
assert_equal(1, #spring_definitions, "one Spring service should be discovered")
local spring = spring_definitions[1]
assert_equal("springboot", spring.service_type, "Spring definitions should have a type")
assert_equal("OrderApplication", spring.name, "Spring definitions should use the class name")
assert_equal("springboot::" .. project_root .. "::com.example.order.OrderApplication", spring.key,
  "Spring definitions should use a stable key")
assert_equal("com.example.order.OrderApplication", spring.metadata.main_class,
  "Spring definitions should retain the main class")
assert_equal(project_root, spring.metadata.project_root, "Spring definitions should retain the project root")
assert_equal({ "mvn", "-Pdev", "-Dstyle.color=always", "spring-boot:run", "-Dspring-boot.run.mainClass=com.example.order.OrderApplication" },
  spring.prepare(spring, "dev"), "Spring preparation should inject the selected Maven profile")

local spring_metadata = vim.deepcopy(spring.metadata)
assert(spring.parse_line(spring_metadata, "Tomcat started on port(s): 8080 (http) with context path '/api'"),
  "Spring parser should report a port update")
assert_equal("http://localhost:8080/api", spring_metadata.url, "Spring parser should build the service URL")
assert(spring.parse_line(spring_metadata, "Started OrderApplication in 1.23 seconds"),
  "Spring parser should report readiness")
assert_equal(true, spring_metadata.ready, "Spring parser should mark services ready")

vim.fn.writefile({
  '{',
  '  "name": "demo-web",',
  '  "scripts": { "dev": "vite", "build": "vite build" }',
  '}',
}, project_root .. "/package.json")
vim.fn.writefile({}, project_root .. "/package-lock.json")

local npm = require("services.providers.npm")
local npm_definitions = npm.discover({ dir = project_root })
assert_equal(2, #npm_definitions, "npm provider should discover every script")
local npm_dev
for _, definition in ipairs(npm_definitions) do
  if definition.name == "dev" then npm_dev = definition end
end
assert(npm_dev, "npm provider should expose the dev script")
assert_equal("npm", npm_dev.service_type, "npm definitions should have a type")
assert_equal({ "npm", "run", "dev" }, npm_dev.cmd, "npm provider should select npm from its lockfile")
assert_equal("npm::" .. project_root .. "::dev", npm_dev.key, "npm definitions should use a stable key")
assert_equal("1", npm_dev.env.FORCE_COLOR, "npm provider should force color through non-TTY pipes")

local npm_metadata = vim.deepcopy(npm_dev.metadata)
assert(npm_dev.parse_line(npm_metadata, "VITE v8.0.0 ready in 3204 ms"),
  "npm parser should report Vite readiness")
assert(npm_dev.parse_line(npm_metadata, "  Local:   http://localhost:5174/"),
  "npm parser should report Vite port discovery")
assert_equal("http://localhost:5174", npm_metadata.url, "npm parser should build the service URL")

package.loaded["custom.services"] = {
  load = function()
    return {
      {
        name = "redis",
        cmd = { "redis-server" },
        auto_restart = true,
        health_check = "redis-cli ping",
      },
    }
  end,
}
local custom = require("services.providers.custom")
local custom_definitions = custom.discover({ dir = project_root })
assert_equal(1, #custom_definitions, "custom provider should load project services")
assert_equal("service::redis", custom_definitions[1].key, "custom services should use name keys")
assert_equal(true, custom_definitions[1].restart.auto, "custom restart configuration should be preserved")
assert_equal("redis-cli ping", custom_definitions[1].health_check, "custom health checks should be preserved")

local providers = require("services.providers")
local all_definitions = providers.discover(project_root)
assert_equal(4, #all_definitions, "combined discovery should include every provider definition")
assert_equal("npm", all_definitions[1].service_type, "combined discovery should be sorted by type and name")

vim.fn.delete(temp_dir, "rf")
print("services-provider-tests: ok")
