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

local state = require("services.state")
local state_path = temp_dir .. "/services.json"
state.setup({ path = state_path })

assert_equal(nil, state.get_profile("/project/a"), "missing profile should be nil")
assert(state.set_profile("/project/a", "dev"), "profile write should succeed")
assert_equal("dev", state.get_profile("/project/a"), "profile should be cached")
assert_equal({}, state.get_selected_services("/project/a"), "old profile state should have no services")

assert(state.set_selected_services("/project/a", { "npm::web::dev", "springboot::orders", "npm::web::dev" }),
  "service selection should persist")
assert_equal({ "npm::web::dev", "springboot::orders" }, state.get_selected_services("/project/a"),
  "service keys should be unique and sorted")
assert_equal("dev", state.get_profile("/project/a"), "service selection should preserve the profile")

local disk_state = vim.json.decode(table.concat(vim.fn.readfile(state_path), "\n"))
disk_state.projects["/project/b"] = { profile = "qa" }
vim.fn.writefile({ vim.json.encode(disk_state) }, state_path)
assert(state.set_profile("/project/a", "prod"), "profile writes should merge the newest disk state")
assert_equal("qa", state.get_profile("/project/b"), "external project updates should not be overwritten")

assert(state.set_selected_services("/project/a", {}), "empty selections should persist")
assert_equal({}, state.get_selected_services("/project/a"), "empty selections should round-trip")
assert_equal("prod", state.get_profile("/project/a"), "empty selections should preserve the profile")

vim.fn.writefile({ '{"projects":{"/project/a":{"selected_services":["npm::dev",42,"npm::dev"]}}}' }, state_path)
state.setup({ path = state_path })
assert_equal({ "npm::dev" }, state.get_selected_services("/project/a"),
  "invalid and duplicate service keys should be ignored")

local project_root = temp_dir .. "/project"
vim.fn.mkdir(project_root, "p")
vim.fn.writefile({
  "<project>",
  "  <profiles>",
  "    <profile><id> dev </id></profile>",
  "    <profile><id>local</id></profile>",
  "    <profile><id>dev</id></profile>",
  "  </profiles>",
  "</project>",
}, project_root .. "/pom.xml")
assert_equal({ "dev", "local" }, state.parse_maven_profiles(project_root), "profiles should be unique and sorted")

local catalog = require("services.catalog")
assert_equal("Spring Boot", catalog.get_type("springboot").label, "Spring type should be registered")
assert_equal("npm", catalog.get_type("npm").label, "npm type should be registered")
assert_equal("Service", catalog.get_type("unknown").label, "unknown types should use the fallback")

assert_equal("springboot::module::com.example.App", catalog.key_from_definition({
  service_type = "springboot",
  metadata = { task_key = "module::com.example.App" },
}), "Spring keys should use task identity metadata")
assert_equal("npm::/project/web::dev", catalog.key_from_definition({
  service_type = "npm",
  metadata = { package_dir = "/project/web", script = "dev" },
}), "npm keys should include package directory and script")
assert_equal("service::redis", catalog.key_from_definition({
  service_type = "service",
  name = "redis",
}), "custom service keys should use their names")

local definitions = {
  { key = "springboot::orders", service_type = "springboot", name = "Orders" },
  { key = "springboot::users", service_type = "springboot", name = "Users" },
  { key = "npm::web::dev", service_type = "npm", name = "web:dev" },
}
assert_equal({ definitions[1], definitions[3] }, catalog.filter_selected(definitions, {
  "springboot::orders",
  "npm::web::dev",
}), "catalog should return only selected definitions")
assert_equal({ "npm::missing::dev", "npm::web::dev", "springboot::users" }, catalog.replace_category(
  { "springboot::orders", "npm::web::dev", "npm::missing::dev" },
  definitions,
  "springboot",
  { "springboot::users" }
), "replacing a category should preserve other categories and stale keys")

vim.fn.delete(temp_dir, "rf")
print("services-state-catalog-tests: ok")
