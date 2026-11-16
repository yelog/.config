local config = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local data = vim.fn.stdpath("data")
local site = data .. "/site"
vim.opt.runtimepath:prepend(config)
vim.opt.runtimepath:prepend(site)
vim.opt.runtimepath:append(config .. "/after")
vim.opt.runtimepath:append(data .. "/lazy/nvim-treesitter")
vim.opt.runtimepath:append(data .. "/lazy/nvim-treesitter-textobjects")

local function assert_equal(expected, actual, message)
  assert(
    vim.deep_equal(expected, actual),
    message .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual)
  )
end

local function flush()
  local finished = false
  vim.schedule(function()
    finished = true
  end)
  assert(
    vim.wait(1000, function()
      return finished
    end),
    "Scheduled startup work must finish"
  )
end

local function buffer(filetype, lines, buftype)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines or { "" })
  vim.bo[bufnr].buftype = buftype or ""
  vim.bo[bufnr].filetype = filetype
  return bufnr
end

local function enter(bufnr)
  vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = bufnr, modeline = false })
end

local function filetype_event(bufnr)
  vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr, modeline = false })
end

local function active(bufnr, language)
  local highlighter = assert(vim.treesitter.highlighter.active[bufnr], "Missing highlighter for " .. language)
  assert_equal(language, highlighter.tree:lang(), "The actual highlighter must use the mapped language")
  assert(highlighter.tree:parse(true)[1], "The active parser must parse the buffer")
  return highlighter
end

local function query_text(language, name)
  local contents = {}
  for _, path in ipairs(vim.treesitter.query.get_files(language, name)) do
    contents[#contents + 1] = table.concat(vim.fn.readfile(path), "\n")
  end
  return table.concat(contents, "\n")
end

local treesitter = require("nvim-treesitter")
local async = require("nvim-treesitter.async")
local original_install = treesitter.install
local installs, completions = {}, {}
treesitter.install = function(languages)
  installs[#installs + 1] = vim.deepcopy(languages)
  assert(original_install({}):wait(1000), "The real installer must emit its TSUpdate event")
  return async.arun(function()
    return async.await(1, function(finish)
      completions[#completions + 1] = finish
    end)
  end)
end

local warnings = {}
vim.notify = function(message, level)
  warnings[#warnings + 1] = { message = message, level = level }
end

local original_start = vim.treesitter.start
local starts, fail_after_start = {}, {}
vim.treesitter.start = function(bufnr, language)
  starts[bufnr] = (starts[bufnr] or 0) + 1
  original_start(bufnr, language)
  if fail_after_start[bufnr] then
    error("Transient failure after highlighter registration", 0)
  end
end

local original_add = vim.treesitter.language.add
local missing_parsers = { python = true }
vim.treesitter.language.add = function(language, options)
  if missing_parsers[language] then
    return nil, 'No parser for language "' .. language .. '" (transient failure)'
  end
  return original_add(language, options)
end

local original_runtime_files = vim.api.nvim_get_runtime_file
local missing_toml_query = true
vim.api.nvim_get_runtime_file = function(pattern, all)
  if missing_toml_query and pattern == "queries/toml/highlights.scm" then
    return {}
  end
  return original_runtime_files(pattern, all)
end

local yaml_highlights = query_text("yaml", "highlights")
vim.treesitter.query.set("yaml", "highlights", "(startup_missing_node) @keyword")
vim.treesitter.language.register("java", "startup_java")

local java = buffer("java", { "class Main { int value = 1; }" })
vim.api.nvim_set_current_buf(java)
local scss = buffer("scss", { "$color: red;", ".example { color: $color; }" })
local shell = buffer("sh", { "echo ready" })
local jsx = buffer("javascriptreact", { "const view = <div />;" })
local alias = buffer("startup_java", { "class Alias {}" })
local composite = buffer("java.spring", { "class Composite {}" })
local lua = buffer("lua", { "local value = 1" })
original_start(lua, "lua")
local existing = active(lua, "lua")
local python = buffer("python", { "value = 1" })
local yaml = buffer("yaml", { "value: 1" })
local toml = buffer("toml", { "value = 1" })
local unsupported = buffer("startup_unsupported")
local empty = buffer("")
local special = {}
for _, buftype in ipairs({ "nofile", "prompt", "acwrite", "nowrite" }) do
  special[#special + 1] = buffer("java", { "class Special {}" }, buftype)
end
local terminal = buffer("java")
vim.api.nvim_open_term(terminal, {})
special[#special + 1] = terminal
local unloaded = vim.fn.bufadd(vim.fn.tempname() .. ".java")
vim.bo[unloaded].filetype = "java"
assert(not vim.api.nvim_buf_is_loaded(unloaded), "The unloaded fixture must stay unloaded")
assert_equal(-1, vim.fn.bufwinid(scss), "The startup scan must also cover hidden loaded buffers")

local spec = dofile(config .. "/lua/plugins/lsp/treesitter.lua")[1]
spec.config()
assert_equal({
  "java",
  "javascript",
  "typescript",
  "python",
  "go",
  "vue",
  "lua",
  "bash",
  "json",
  "yaml",
  "markdown",
  "markdown_inline",
  "html",
  "css",
  "scss",
  "rust",
  "toml",
  "xml",
  "sql",
}, installs[1], "The existing asynchronous parser installation list must be preserved")
local java_highlighter = active(java, "java")
active(scss, "scss")
active(shell, "bash")
active(jsx, "javascript")
active(alias, "java")
active(composite, "java")
assert_equal(existing, active(lua, "lua"), "Setup must retain an existing highlighter")
assert_equal(nil, starts[lua], "Setup must not restart an already active highlighter")
for _, bufnr in ipairs({ python, yaml, toml, unsupported, empty, unloaded, unpack(special) }) do
  assert_equal(nil, vim.treesitter.highlighter.active[bufnr], "Unavailable or special buffers must stay inactive")
end
assert_equal(0, #warnings, "Pending first-time installation must not produce startup warnings")
flush()
assert_equal(0, #warnings, "The installer's early TSUpdate event must stay quiet while installation is pending")
assert_equal(nil, vim.treesitter.query.get("toml", "highlights"), "A missing query must exercise the real query cache")

for _ = 1, 3 do
  filetype_event(java)
  enter(java)
end
assert_equal(1, starts[java], "Repeated FileType and BufWinEnter must not duplicate successful starts")
assert_equal(java_highlighter, active(java, "java"), "Repeated entry must retain the actual highlighter")
for _, bufnr in ipairs(special) do
  local buftype, syntax = vim.bo[bufnr].buftype, vim.bo[bufnr].syntax
  filetype_event(bufnr)
  enter(bufnr)
  assert_equal(nil, starts[bufnr], "Special buffers must never attempt activation")
  assert_equal(buftype, vim.bo[bufnr].buftype, "Terminal and prompt buffer types must be preserved")
  assert_equal(syntax, vim.bo[bufnr].syntax, "Special buffer syntax must be preserved")
end

missing_parsers.python = nil
missing_toml_query = false
completions[1](true)
assert(
  vim.wait(1000, function()
    return vim.treesitter.highlighter.active[python] and vim.treesitter.highlighter.active[toml]
  end),
  "Actual async task completion must activate newly available parsers and queries without re-entry"
)
active(python, "python")
active(toml, "toml")
assert_equal(nil, vim.treesitter.highlighter.active[yaml], "A broken query must remain retryable")
assert_equal(1, #warnings, "Only a failure persisting after installation should warn")
assert_equal(vim.log.levels.WARN, warnings[1].level, "Activation failures should be warnings")
assert(warnings[1].message:find("yaml", 1, true), "A warning must name the affected language")
assert(warnings[1].message:find("startup_missing_node", 1, true), "A warning must preserve the query error")
assert(warnings[1].message:find(":TSUpdate yaml", 1, true), "A warning must give a useful recovery command")

local second_yaml = buffer("yaml", { "second: true" })
for _ = 1, 3 do
  enter(yaml)
  filetype_event(yaml)
  enter(second_yaml)
end
assert_equal(1, #warnings, "The same query failure must be deduplicated across events and buffers")
local autocmd_count = #vim.api.nvim_get_autocmds({ group = "custom_treesitter_startup" })
spec.config()
assert_equal(
  autocmd_count,
  #vim.api.nvim_get_autocmds({ group = "custom_treesitter_startup" }),
  "Repeated setup must replace the named augroup's handlers"
)
completions[2](true)
flush()
assert_equal(1, #warnings, "Repeated setup must preserve warning deduplication")
assert_equal(1, starts[java], "Repeated setup and task completion must retain successful starts")

vim.treesitter.query.set("yaml", "highlights", yaml_highlights)
assert(original_install({}):wait(1000), "The real TSUpdate event must remain usable after setup")
assert(
  vim.wait(1000, function()
    return vim.treesitter.highlighter.active[yaml] and vim.treesitter.highlighter.active[second_yaml]
  end),
  "The installed plugin's actual TSUpdate event must recover failed loaded buffers"
)
active(yaml, "yaml")
active(second_yaml, "yaml")
assert_equal(1, #warnings, "Successful query recovery must stay quiet")

missing_parsers.rust = true
local rust = buffer("rust", { "fn main() {}" })
local second_rust = buffer("rust", { "fn second() {}" })
enter(rust)
filetype_event(second_rust)
assert_equal(nil, vim.treesitter.highlighter.active[rust], "A transient parser failure must not become success")
assert_equal(2, #warnings, "Identical parser failures in multiple buffers should warn once")
assert(warnings[2].message:find('No parser for language "rust"', 1, true), "Parser warnings must retain the cause")
missing_parsers.rust = nil
enter(rust)
active(rust, "rust")
assert_equal(1, starts[rust], "BufWinEnter must retry a previously unavailable parser")

local xml_injections = query_text("xml", "injections")
vim.treesitter.query.set("xml", "injections", "(startup_invalid_injection) @injection.content")
local xml = buffer("xml", { '<mapper namespace="Example"><select id="find">SELECT id FROM users</select></mapper>' })
assert_equal(nil, vim.treesitter.highlighter.active[xml], "Injection query errors must also remain retryable")
assert_equal(3, #warnings, "A distinct injection query failure should produce a useful warning")
assert(
  warnings[3].message:find("startup_invalid_injection", 1, true),
  "Injection warnings must preserve the real query error"
)
vim.treesitter.query.set("xml", "injections", xml_injections)
filetype_event(xml)
local xml_highlighter = active(xml, "xml")
assert(xml_highlighter.tree:children().sql, "Recovered XML must retain the custom MyBatis SQL injection")

local partial = buffer("", { "class Partial {}" })
fail_after_start[partial] = true
vim.bo[partial].filetype = "java"
assert_equal(nil, vim.treesitter.highlighter.active[partial], "A failed start must clean up partial activation")
assert_equal(4, #warnings, "A failed start after registration should still be reported")
fail_after_start[partial] = nil
enter(partial)
active(partial, "java")
assert_equal(2, starts[partial], "A partial start must remain retryable")
vim.bo[partial].filetype = "javascript"
active(partial, "javascript")
assert_equal(3, starts[partial], "A changed filetype must replace the previous language's highlighter")
enter(partial)
assert_equal(3, starts[partial], "The replacement highlighter must also be idempotent")

vim.treesitter.stop(java)
enter(java)
active(java, "java")
assert_equal(2, starts[java], "Recovery must use real activation state after an external stop")
vim.opt.runtimepath:prepend(config)
enter(java)
assert_equal(site, vim.opt.runtimepath:get()[1], "Buffer entry must restore the installed queries' precedence")
assert_equal(2, starts[java], "Restoring runtimepath must not restart a successful highlighter")

spec.config()
spec.config()
missing_parsers.go = true
local go = buffer("go", { "package main", "func main() {}" })
completions[3](true)
flush()
assert_equal(4, #warnings, "A stale setup's completion callback must not report pending current failures")
assert_equal(nil, vim.treesitter.highlighter.active[go], "A stale callback must not activate unavailable parsers")
missing_parsers.go = nil
completions[4](true)
assert(
  vim.wait(1000, function()
    return vim.treesitter.highlighter.active[go]
  end),
  "The current setup's completion callback must still recover pending buffers"
)
active(go, "go")
assert_equal(
  autocmd_count,
  #vim.api.nvim_get_autocmds({ group = "custom_treesitter_startup" }),
  "Repeated setup must never accumulate entry or update handlers"
)
local site_count = 0
for _, path in ipairs(vim.opt.runtimepath:get()) do
  if path == site then
    site_count = site_count + 1
  end
end
assert_equal(1, site_count, "Repeated setup must not duplicate the install runtimepath")
assert(not vim.api.nvim_buf_is_loaded(unloaded), "Startup scans must never load unloaded buffers")
assert_equal(4, #warnings, "Successful recovery must not add notifications")
assert(vim.fn.maparg("as", "x") ~= "", "Local-scope textobjects must remain configured")

print("treesitter-startup-tests: ok")
