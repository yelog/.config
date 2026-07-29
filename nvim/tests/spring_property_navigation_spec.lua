package.path = "/Users/yelog/.config/nvim/lua/?.lua;" .. package.path

local nav = require("custom.spring_property_navigation")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
  end
end

assert_equal(nav._placeholder_at("path: ${spring.application.name}", 20), "spring.application.name", "extract placeholder key")
assert_equal(nav._placeholder_at("path: ${server.port:8080}", 22), "server.port", "ignore placeholder default")
assert_equal(nav._placeholder_at("path: plain-value", 8), nil, "ignore text outside placeholders")

local yaml_properties = nav._yaml_properties({
  "spring:",
  "  application:",
  "    name: orders",
  "server:",
  "  port: 8080",
})
assert_equal(yaml_properties[1].key, "spring.application.name", "flatten nested YAML keys")
assert_equal(yaml_properties[1].row, 3, "preserve YAML key row")
assert_equal(yaml_properties[2].key, "server.port", "parse sibling YAML branch")

local properties = nav._properties({ "spring.application.name=orders", "server.port:8080" })
assert_equal(properties[1].key, "spring.application.name", "parse equals properties key")
assert_equal(properties[2].key, "server.port", "parse colon properties key")

local root = vim.fn.tempname()
local resources = root .. "/module/src/main/resources"
vim.fn.mkdir(resources, "p")
local config = resources .. "/application.yml"
vim.fn.writefile({ "spring:", "  application:", "    name: orders" }, config)
local target = nav._find_property(root, "spring.application.name")
assert_equal(target.path, config, "find properties in Spring resources")
assert_equal(target.row, 3, "return definition row")
vim.fn.delete(root, "rf")

print("spring-property-navigation-tests: ok")
