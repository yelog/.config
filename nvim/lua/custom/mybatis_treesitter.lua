local M = {}

local statements = { select = true, insert = true, update = true, delete = true, sql = true, selectKey = true }
local dynamic_tags = {
  where = true, set = true, trim = true, ["if"] = true, foreach = true,
  choose = true, when = true, otherwise = true,
}

function M.setup()
  vim.treesitter.query.add_predicate("mybatis-sql?", function(match, _, source, predicate)
    local nodes = match[predicate[2]]
    if not nodes or #nodes == 0 then return false end
    for _, node in ipairs(nodes) do
      local in_statement, in_mapper = false, false
      local parent = node:parent()
      while parent do
        if parent:type() == "element" then
          local start_tag = parent:named_child(0)
          local name_node = start_tag and start_tag:named_child(0)
          local name = name_node and vim.treesitter.get_node_text(name_node, source)
          if name == "mapper" then
            in_mapper = parent:parent() ~= nil and parent:parent():type() == "document"
            break
          elseif statements[name] then
            in_statement = true
          elseif not dynamic_tags[name] then
            return false
          end
        end
        parent = parent:parent()
      end
      if not (in_statement and in_mapper) then return false end
    end
    return true
  end, { force = true })
end

return M
