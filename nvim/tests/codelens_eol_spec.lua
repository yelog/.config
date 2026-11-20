local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = root .. "/lua/?.lua;" .. package.path

local codelens_eol = require("custom.codelens_eol")

local function equal(expected, actual, message)
  assert(
    vim.deep_equal(expected, actual),
    (message or "values differ") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual)
  )
end

local function marks(bufnr)
  local namespace = vim.api.nvim_get_namespaces()["nvim.codelens_eol"]
  return vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, { details = true })
end

local bufnr = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
  "class Example {",
  "  void first() {}",
  "  void second() {}",
  "}",
})

local client = {
  id = 77,
  name = "jdtls",
  request = function(_, method, params, callback)
    if method == "textDocument/codeLens" then
      callback(nil, {
        {
          range = { start = { line = 0, character = 6 }, ["end"] = { line = 0, character = 13 } },
          command = { title = "0 references" },
        },
        {
          range = { start = { line = 1, character = 7 }, ["end"] = { line = 1, character = 12 } },
          command = { title = "1 reference" },
        },
        {
          range = { start = { line = 2, character = 7 }, ["end"] = { line = 2, character = 13 } },
        },
      })
    elseif method == "codeLens/resolve" then
      local resolved = vim.tbl_extend("force", params, { command = { title = "2 references" } })
      callback(nil, resolved)
    end
  end,
}

codelens_eol.attach(bufnr, client)
assert(
  vim.wait(1000, function()
    return #marks(bufnr) == 3
  end),
  "all CodeLens entries should be rendered"
)

local rendered = marks(bufnr)
table.sort(rendered, function(a, b)
  return a[2] < b[2]
end)

for index, expected in ipairs({ "0 references", "1 reference", "2 references" }) do
  local mark = rendered[index]
  equal(index - 1, mark[2], "CodeLens should stay on its declaration row")
  equal("eol", mark[4].virt_text_pos, "CodeLens should render at end of line")
  equal("  " .. expected, mark[4].virt_text[1][1], "CodeLens title should be preserved")
  equal("LspCodeLens", mark[4].virt_text[1][2], "CodeLens should use the theme highlight")
  equal(nil, mark[4].virt_lines, "CodeLens should not add virtual lines")
end

codelens_eol.detach(bufnr, client.id)
equal({}, marks(bufnr), "detaching jdtls should remove every CodeLens extmark")
vim.api.nvim_buf_delete(bufnr, { force = true })

print("codelens-eol-tests: ok")
