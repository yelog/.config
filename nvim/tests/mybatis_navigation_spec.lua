package.path = "/Users/yelog/.config/nvim/lua/?.lua;" .. package.path

local nav = require("custom.mybatis_navigation")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
  end
end

local java_lines = {
  "package com.example.order.mapper;",
  "import com.baomidou.mybatisplus.core.mapper.BaseMapper;",
  "@Mapper",
  "public interface OrderMapper extends BaseMapper<Order> {",
  "  List<Order> findByCustomerId(Long customerId);",
  "}",
}

local mapper = nav._parse_java(java_lines)
assert_equal(mapper.fqcn, "com.example.order.mapper.OrderMapper", "parse Mapper FQCN")
assert_equal(nav._parse_java({ "package com.example;", "class NotMapper {}" }), nil, "ignore non-Mapper Java")

local xml = nav._parse_xml({
  '<?xml version="1.0"?>',
  '<mapper namespace="com.example.order.mapper.OrderMapper">',
  '  <select id="findByCustomerId">select 1</select>',
  "</mapper>",
})
assert_equal(xml.namespace, "com.example.order.mapper.OrderMapper", "parse XML namespace")

local statement = nav._statement_at({
  '<mapper namespace="com.example.order.mapper.OrderMapper">',
  '  <select id="findByCustomerId">',
  "    select 1",
  "  </select>",
  "</mapper>",
}, 3)
assert_equal(statement.id, "findByCustomerId", "find enclosing statement")
assert_equal(nav._method_at(java_lines, 5), "findByCustomerId", "find Java method")
assert_equal(nav._method_at({ "if (enabled) {" }, 1), nil, "ignore Java keyword")

print("mybatis-navigation-tests: ok")
