local navigation = require("custom.mybatis_navigation")

local M = {}
local namespace = vim.api.nvim_create_namespace("mybatis-missing-statement")

local prefixes = {
  insert = { "insert", "add", "create", "save" },
  update = { "update", "modify", "edit" },
  delete = { "delete", "del", "remove" },
  select = { "select", "query", "get", "find", "list", "count", "exists" },
}

local function classify(method)
  local lower = method:lower()
  for tag, names in pairs(prefixes) do
    for _, prefix in ipairs(names) do
      if lower:sub(1, #prefix) == prefix then
        return tag
      end
    end
  end
end

local function mapper_context(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or vim.bo[bufnr].filetype ~= "java" then return nil end
  local mapper = navigation._parse_java(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  local root = mapper and navigation._maven_root(path) or nil
  if not mapper or not root then return nil end
  return { bufnr = bufnr, path = path, mapper = mapper, root = root }
end

local function matching_xml(context)
  return navigation._xml_for_namespace(context.root, context.mapper.fqcn)
end

function M.classify(method)
  return classify(method)
end

function M.build_diagnostics(methods, statements)
  local ids = {}
  for _, statement in ipairs(statements) do
    ids[statement.id] = true
  end

  local diagnostics = {}
  for _, method in ipairs(methods) do
    local tag = classify(method.name)
    if tag and not ids[method.name] then
      table.insert(diagnostics, {
        lnum = method.row - 1,
        col = method.col,
        end_lnum = method.row - 1,
        end_col = method.end_col,
        severity = vim.diagnostic.severity.ERROR,
        message = string.format("Missing MyBatis <%s id=\"%s\"> statement", tag, method.name),
        source = "mybatis",
        code = "missing-mybatis-statement",
        user_data = { method = method.name, tag = tag },
      })
    end
  end
  return diagnostics
end

function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local context = mapper_context(bufnr)
  if not context then
    vim.diagnostic.reset(namespace, bufnr)
    return {}
  end

  local xmls = matching_xml(context)
  local statements = navigation._statement_details(xmls)
  local methods = navigation._java_methods(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  local diagnostics = M.build_diagnostics(methods, statements)
  vim.diagnostic.set(namespace, bufnr, diagnostics, {})
  return diagnostics
end

local function insert_lines(lines, tag, id)
  local closing
  for index, line in ipairs(lines) do
    if line:match("^%s*</mapper>%s*$") then
      closing = index
      break
    end
  end
  if not closing then return nil end

  local indent = lines[closing]:match("^(%s*)") or ""
  local generated = {
    indent .. "<" .. tag .. " id=\"" .. id .. "\">",
    indent .. "  <!-- TODO: implement SQL -->",
    indent .. "</" .. tag .. ">",
  }
  for offset, line in ipairs(generated) do
    table.insert(lines, closing + offset - 1, line)
  end
  return closing, #generated
end

local function write_statement(path, tag, id)
  local lines = navigation._read_file(path)
  if not lines then return nil end
  for _, statement in ipairs(navigation._statement_details({ path })) do
    if statement.id == id then return nil end
  end

  local row, count = insert_lines(lines, tag, id)
  if not row then return nil end
  if vim.fn.writefile(lines, path) ~= 0 then return nil end
  return row, count
end

function M.generate(diagnostic, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local context = mapper_context(bufnr)
  if not context or not diagnostic.user_data then return false end
  local xmls = matching_xml(context)
  if #xmls ~= 1 then
    vim.notify("MyBatis: expected exactly one matching XML file", vim.log.levels.WARN)
    return false
  end

  local path = xmls[1]
  local row = write_statement(path, diagnostic.user_data.tag, diagnostic.user_data.method)
  if not row then
    vim.notify("MyBatis: failed to generate or statement already exists", vim.log.levels.WARN)
    return false
  end
  M.refresh(bufnr)

  local xml_buf = vim.fn.bufadd(path)
  vim.fn.bufload(xml_buf)
  vim.api.nvim_buf_set_lines(xml_buf, 0, -1, false, navigation._read_file(path))
  vim.api.nvim_buf_call(xml_buf, function() vim.cmd.write({ mods = { silent = true } }) end)
  vim.api.nvim_set_current_buf(xml_buf)
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
  return true
end

local function diagnostic_at_cursor(bufnr)
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  for _, diagnostic in ipairs(vim.diagnostic.get(bufnr, { namespace = namespace, lnum = row })) do
    if diagnostic.code == "missing-mybatis-statement" then return diagnostic end
  end
end

local function apply_lsp_action(choice, bufnr)
  local client = vim.lsp.get_client_by_id(choice.client_id)
  if not client then return end
  local action = choice.action
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end
  if action.command then
    local command = type(action.command) == "table" and action.command or action
    client:exec_cmd(command, { bufnr = bufnr, client_id = client.id })
  end
end

function M.code_action()
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostic = diagnostic_at_cursor(bufnr)
  if not diagnostic then
    return vim.lsp.buf.code_action()
  end

  local params = vim.lsp.util.make_range_params(0, "utf-16")
  params.context = {
    diagnostics = vim.diagnostic.get(bufnr),
    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
  }
  vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", params, function(results)
    local choices = {}
    for client_id, response in pairs(results) do
      for _, action in ipairs(response.result or {}) do
        table.insert(choices, { label = action.title, action = action, client_id = client_id })
      end
    end

    table.insert(choices, {
      label = "Generate <" .. diagnostic.user_data.tag .. "> for " .. diagnostic.user_data.method,
      mybatis = diagnostic,
    })
    vim.ui.select(choices, {
      prompt = "Code actions",
      format_item = function(item) return item.label end,
    }, function(choice)
      if not choice then return end
      if choice.mybatis then
        M.generate(choice.mybatis, bufnr)
      else
        apply_lsp_action(choice, bufnr)
      end
    end)
  end)
end

function M.attach(bufnr)
  local group = vim.api.nvim_create_augroup("mybatis_diagnostics_" .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group = group,
    buffer = bufnr,
    callback = function() M.refresh(bufnr) end,
  })
  M.refresh(bufnr)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("mybatis_xml_diagnostics", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.xml",
    callback = function(args)
      local parsed = navigation._parse_xml(navigation._read_file(args.file) or {})
      if not parsed then return end
      local root = navigation._maven_root(args.file)
      if not root then return end
      for _, path in ipairs(navigation._java_for_namespace(root, parsed.namespace)) do
        local bufnr = vim.fn.bufnr(path)
        if bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr) then M.refresh(bufnr) end
      end
    end,
  })
end

M._insert_lines = insert_lines
M._namespace = namespace

return M
