package.path = "/Users/yelog/.config/nvim/lua/?.lua;" .. package.path

local diagnostics = require("custom.mybatis_diagnostics")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
  end
end

assert_equal(diagnostics.classify("addOrder"), "insert", "add methods use insert")
assert_equal(diagnostics.classify("insertOrder"), "insert", "insert methods use insert")
assert_equal(diagnostics.classify("delOrder"), "delete", "del methods use delete")
assert_equal(diagnostics.classify("deleteOrder"), "delete", "delete methods use delete")
assert_equal(diagnostics.classify("queryOrder"), "select", "query methods use select")
assert_equal(diagnostics.classify("getOrder"), "select", "get methods use select")
assert_equal(diagnostics.classify("selectOrder"), "select", "select methods use select")
assert_equal(diagnostics.classify("rebuildOrder"), nil, "unknown methods are not guessed")

local missing = diagnostics.build_diagnostics({
  { name = "addOrder", row = 2, col = 2, end_col = 10 },
  { name = "queryOrder", row = 3, col = 2, end_col = 12 },
  { name = "deleteOrder", row = 4, col = 2, end_col = 13 },
}, {
  { id = "queryOrder", tag = "select" },
})
assert_equal(#missing, 2, "only missing statements produce diagnostics")
assert_equal(missing[1].user_data.tag, "insert", "diagnostic stores generated tag")
assert_equal(missing[2].user_data.tag, "delete", "diagnostic stores delete tag")
assert_equal(missing[1].severity, vim.diagnostic.severity.ERROR, "missing statement is an error")

local lines = {
  '<mapper namespace="com.example.OrderMapper">',
  '  <select id="queryOrder">select 1</select>',
  "  </mapper>",
}
local row = diagnostics._insert_lines(lines, "insert", "addOrder")
assert_equal(row, 3, "insert before mapper closing tag")
assert_equal(lines[3], '  <insert id="addOrder">', "generated opening tag")
assert_equal(lines[4], "    <!-- TODO: implement SQL -->", "generated SQL placeholder")
assert_equal(lines[5], "  </insert>", "generated closing tag")
assert_equal(lines[6], "  </mapper>", "preserve mapper closing tag")

local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/src/main/java/com/example", "p")
vim.fn.mkdir(root .. "/src/main/resources", "p")
vim.fn.writefile({ "<project/>" }, root .. "/pom.xml")
local java_path = root .. "/src/main/java/com/example/OrderMapper.java"
local xml_path = root .. "/src/main/resources/OrderMapper.xml"
vim.fn.writefile({
  "package com.example;",
  "@Mapper",
  "public interface OrderMapper {",
  "  Order addOrder(Order order);",
  "}",
}, java_path)
vim.fn.writefile({
  '<mapper namespace="com.example.OrderMapper">',
  "  </mapper>",
}, xml_path)
vim.cmd("edit " .. vim.fn.fnameescape(java_path))
vim.bo.filetype = "java"
local generated_diagnostics = diagnostics.refresh(0)
assert_equal(#generated_diagnostics, 1, "refresh detects missing XML statement")
assert_equal(diagnostics.generate(generated_diagnostics[1], 0), true, "generate missing XML statement")
assert_equal(#diagnostics.refresh(0), 0, "generation clears the Mapper diagnostic")
local generated_xml = vim.fn.readfile(xml_path)
assert_equal(generated_xml[2], '  <insert id="addOrder">', "write generated XML opening tag")
vim.fn.delete(root, "rf")

print("mybatis-diagnostics-tests: ok")
