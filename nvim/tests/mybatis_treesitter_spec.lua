-- Run with: nvim --headless -u NONE -i NONE -l nvim/tests/mybatis_treesitter_spec.lua
local config = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(config)
vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/site")
vim.opt.runtimepath:append(config .. "/after")
require("custom.mybatis_treesitter").setup()

local source = [=[
<mapper namespace="example.Mapper">
  <select id="find">
    SELECT id FROM users WHERE id = #{id}
    <where><if test="name != null"><trim>
      AND name = 'alice'
    </trim></if></where>
    <foreach collection="ids" item="id">#{id, jdbcType=INTEGER}</foreach>
    <choose><when test="enabled">AND active = 1</when><otherwise>AND active = 0</otherwise></choose>
    <![CDATA[ AND score < 10 ]]>
    <!-- SELECT hidden FROM comments -->
    ORDER BY ${column}
  </select>
  <insert id="add">INSERT INTO users (id) VALUES (#{id})<selectKey keyProperty="id">SELECT 1</selectKey></insert>
  <update id="edit">UPDATE users<set><if test="name != null">name = #{name}</if></set>WHERE id = #{id}</update>
  <delete id="remove">DELETE FROM users WHERE id = #{id}</delete>
  <sql id="columns">id, name</sql>
  <resultMap id="result" type="User">SELECT not_sql</resultMap>
  <if test="true">SELECT outside_statement</if>
</mapper>
]=]

local parser = vim.treesitter.get_string_parser(source, "xml")
local root = parser:parse(true)[1]:root()
assert(not root:has_error(), "fixture must be valid XML")
assert(parser:children().sql, "Mapper must have an SQL language tree")
local injection = assert(vim.treesitter.query.get("xml", "injections"))
local texts = {}
for _, match, metadata in injection:iter_matches(root, source) do
  if metadata["injection.language"] == "sql" then
    for id, nodes in pairs(match) do
      if injection.captures[id] == "injection.content" then
        for _, node in ipairs(nodes) do
          assert(node:type() == "CharData" or node:type() == "CData", "only inject text nodes")
          texts[#texts + 1] = vim.trim(vim.treesitter.get_node_text(node, source))
        end
      end
    end
  end
end
local injected = table.concat(texts, "\n")
for _, expected in ipairs({
  "SELECT id FROM users WHERE id = #{id}", "AND name = 'alice'", "#{id, jdbcType=INTEGER}",
  "AND active = 1", "AND active = 0", "AND score < 10", "ORDER BY ${column}",
  "INSERT INTO users", "SELECT 1", "UPDATE users", "name = #{name}", "DELETE FROM users", "id, name",
}) do
  assert(injected:find(expected, 1, true), "missing SQL injection: " .. expected)
end
for _, excluded in ipairs({ "hidden", "not_sql", "outside_statement", "test=", "<![CDATA[" }) do
  assert(not injected:find(excluded, 1, true), "must not inject: " .. excluded)
end

local highlights = assert(vim.treesitter.query.get("sql", "highlights"), "SQL highlight query must be installed")
local keywords = {}
parser:for_each_tree(function(tree, language_tree)
  if language_tree:lang() ~= "sql" then return end
  for id, node in highlights:iter_captures(tree:root(), source) do
    if highlights.captures[id]:match("^keyword") then
      keywords[vim.treesitter.get_node_text(node, source):upper()] = true
    end
  end
end)
for _, keyword in ipairs({ "SELECT", "FROM", "INSERT", "UPDATE", "DELETE" }) do
  assert(keywords[keyword], "missing SQL keyword highlight: " .. keyword)
end

for _, xml in ipairs({
  '<project><select>SELECT 1</select><sql>SELECT 2</sql></project>',
  '<configuration><if test="true">SELECT 1</if></configuration>',
  '<document><mapper><select>SELECT 1</select></mapper></document>',
}) do
  local ordinary = vim.treesitter.get_string_parser(xml, "xml")
  ordinary:parse(true)
  assert(not ordinary:children().sql, "ordinary XML must not inject SQL")
end

print("mybatis-treesitter-tests: ok")
