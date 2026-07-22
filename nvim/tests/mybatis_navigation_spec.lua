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

local methods = nav._java_methods({
  "  List<Order> findByCustomerId(Long customerId);",
  "  int updateStatus(Long id, String status);",
  "  if (enabled) {",
})
assert_equal(methods[1].name, "findByCustomerId", "extract Mapper method")
assert_equal(methods[2].name, "updateStatus", "extract multiple Mapper methods")
assert_equal(#methods, 2, "ignore control-flow calls")

local xml_path = vim.fn.tempname()
vim.fn.writefile({
  '<mapper namespace="com.example.OrderMapper">',
  '  <select id="findByCustomerId" parameterType="long">',
  "    select 1",
  "  </select>",
  "</mapper>",
}, xml_path)
local statements = nav._statement_details({ xml_path })
assert_equal(#statements, 1, "parse XML statement")
assert_equal(statements[1].id, "findByCustomerId", "parse XML statement id")
assert_equal(statements[1].tag, "select", "parse XML statement tag")
vim.fn.delete(xml_path)

local sys_dept_mapper = "/Users/yelog/workspace/lenovo/moss/moss-cloud/moss-service-common/moss-service-common-server/src/main/java/com/lenovo/moss/service/common/server/dao/SysDeptMapper.java"
local target = nav._mapper_method_from_location({
  uri = vim.uri_from_fname(sys_dept_mapper),
  range = { start = { line = 18, character = 0 } },
})
assert_equal(target.mapper.fqcn, "com.lenovo.moss.service.common.server.dao.SysDeptMapper", "resolve Mapper definition location")
assert_equal(target.method, "queryAllChildrenId", "resolve Mapper method definition location")

print("mybatis-navigation-tests: ok")
