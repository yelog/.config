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
local store_dir = temp_dir .. "/store"
local project_a = temp_dir .. "/project-a"
local project_b = temp_dir .. "/project-b"
local file_a1 = project_a .. "/src/One.java"
local file_a2 = project_a .. "/src/Two.java"
local file_b = project_b .. "/src/Other.java"

for _, project in ipairs({ project_a, project_b }) do
  vim.fn.mkdir(project .. "/.git", "p")
  vim.fn.mkdir(project .. "/src", "p")
end
vim.fn.writefile({ "class One {", "  void run() {}", "}" }, file_a1)
vim.fn.writefile({ "class Two {", "  void run() {}", "}" }, file_a2)
vim.fn.writefile({ "class Other {", "  void run() {}", "}" }, file_b)

local states = {}
local function get_breakpoints(bufnr)
  if bufnr then
    return states[bufnr] and { [bufnr] = states[bufnr] } or {}
  end
  return states
end

package.loaded["dap.breakpoints"] = {
  get = get_breakpoints,
  set = function(opts, bufnr, line)
    states[bufnr] = states[bufnr] or {}
    table.insert(states[bufnr], {
      buf = bufnr,
      line = line,
      condition = opts.condition,
      hitCondition = opts.hit_condition,
      logMessage = opts.log_message,
    })
  end,
}

local toggle_count = 0
package.loaded.dap = {
  toggle_breakpoint = function()
    toggle_count = toggle_count + 1
  end,
}

local warnings = {}
local persistence = require("custom.dap_breakpoints")
persistence.setup({
  data_dir = store_dir,
  debounce_ms = 0,
  restore_existing = false,
  notify = function(message) table.insert(warnings, message) end,
})

local function load_buffer(path)
  local bufnr = vim.fn.bufadd(path)
  vim.fn.bufload(bufnr)
  return bufnr
end

local buf_a1 = load_buffer(file_a1)
local buf_a2 = load_buffer(file_a2)
local buf_b = load_buffer(file_b)

states[buf_a1] = {
  {
    buf = buf_a1,
    line = 2,
    condition = "order != nil",
    hitCondition = "3",
    logMessage = "order={order}",
  },
}
assert(persistence.sync_buffer(buf_a1), "the first project buffer should be persisted")

states[buf_a2] = { { buf = buf_a2, line = 1 } }
assert(persistence.sync_buffer(buf_a2), "a second file should be merged into the project catalog")

local project_a_path = persistence.storage_path(project_a)
local saved_a = vim.json.decode(table.concat(vim.fn.readfile(project_a_path), "\n"))
assert_equal(1, saved_a.version, "catalogs should have a schema version")
assert_equal(vim.uv.fs_realpath(project_a), saved_a.root, "catalogs should retain their normalized root")
assert_equal(2, saved_a.files["src/One.java"][1].line, "breakpoint lines should be persisted")
assert_equal("order != nil", saved_a.files["src/One.java"][1].condition,
  "conditions should be persisted")
assert_equal("3", saved_a.files["src/One.java"][1].hitCondition,
  "hit conditions should be persisted")
assert_equal("order={order}", saved_a.files["src/One.java"][1].logMessage,
  "log messages should be persisted")
assert_equal(1, saved_a.files["src/Two.java"][1].line,
  "syncing one buffer must preserve another file's breakpoints")

states[buf_b] = {
  {
    buf = buf_b,
    line = 2,
    condition = "ready",
    hitCondition = "5",
    logMessage = "ready={ready}",
  },
  { buf = buf_b, line = 99 },
}
assert(persistence.sync_buffer(buf_b), "a second project should have an independent catalog")
assert(project_a_path ~= persistence.storage_path(project_b), "project roots should not share storage files")

states[buf_a1] = nil
assert(persistence.sync_buffer(buf_a1), "removing the last breakpoint should update the catalog")
saved_a = vim.json.decode(table.concat(vim.fn.readfile(project_a_path), "\n"))
assert_equal(nil, saved_a.files["src/One.java"], "empty file entries should be removed")
assert_equal(1, saved_a.files["src/Two.java"][1].line,
  "removing one file's breakpoints must preserve unopened entries")

states = {}
package.loaded["custom.dap_breakpoints"] = nil
persistence = require("custom.dap_breakpoints")
persistence.setup({
  data_dir = store_dir,
  debounce_ms = 0,
  restore_existing = false,
  notify = function(message) table.insert(warnings, message) end,
})

assert(persistence.restore_buffer(buf_a2), "a persisted file should restore lazily")
assert_equal(1, #states[buf_a2], "restore should set one breakpoint")
assert_equal(1, states[buf_a2][1].line, "restore should preserve the line")
assert(persistence.restore_buffer(buf_a2), "restoring an initialized buffer should be harmless")
assert_equal(1, #states[buf_a2], "restore should not duplicate an existing breakpoint")
assert(persistence.restore_buffer(buf_b), "advanced breakpoints should restore in another project")
assert_equal(1, #states[buf_b], "restore should skip lines outside the current buffer")
assert_equal("ready", states[buf_b][1].condition, "restore should preserve conditions")
assert_equal("5", states[buf_b][1].hitCondition, "restore should preserve hit conditions")
assert_equal("ready={ready}", states[buf_b][1].logMessage, "restore should preserve log messages")

states[buf_a1] = nil
vim.fn.writefile({ "{broken" }, project_a_path)
package.loaded["custom.dap_breakpoints"] = nil
persistence = require("custom.dap_breakpoints")
persistence.setup({
  data_dir = store_dir,
  restore_existing = false,
  notify = function(message) table.insert(warnings, message) end,
})
assert_equal(false, persistence.restore_buffer(buf_a1), "a corrupt catalog should be ignored")
assert(#warnings > 0, "a corrupt catalog should produce a warning")

local autocmds = vim.api.nvim_get_autocmds({ group = "DapBreakpointPersistence" })
local events = {}
for _, autocmd in ipairs(autocmds) do events[autocmd.event] = true end
assert_equal(true, events.BufReadPost, "setup should register lazy buffer restoration")
assert_equal(true, events.VimLeavePre, "setup should register a final persistence hook")

persistence.toggle()
assert_equal(1, toggle_count, "the persistence toggle should delegate to nvim-dap")

vim.fn.delete(temp_dir, "rf")
print("dap-breakpoint-persistence-tests: ok")
