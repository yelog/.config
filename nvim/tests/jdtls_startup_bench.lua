local test_file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:gsub("^@", ""), ":p")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
local fixture_root = assert(arg[1], "Pass an empty temporary directory for the benchmark fixture")
local project_root = fixture_root .. "/project"
local marker = project_root .. "/.nvim-java-startup-bench"
assert(
  vim.fn.isdirectory(project_root) == 0 or vim.fn.filereadable(marker) == 1,
  "The benchmark only accepts its own disposable project"
)

if vim.fn.filereadable(marker) == 0 then
  vim.fn.mkdir(project_root .. "/.git", "p")
  vim.fn.mkdir(project_root .. "/src/main/java/example", "p")
  vim.fn.writefile({ "Java startup benchmark" }, marker)
  vim.fn.writefile({
    '<project xmlns="http://maven.apache.org/POM/4.0.0">',
    "  <modelVersion>4.0.0</modelVersion>",
    "  <groupId>example</groupId>",
    "  <artifactId>nvim-startup-bench</artifactId>",
    "  <version>1.0.0</version>",
    "  <properties>",
    "    <maven.compiler.source>17</maven.compiler.source>",
    "    <maven.compiler.target>17</maven.compiler.target>",
    "  </properties>",
    "</project>",
  }, project_root .. "/pom.xml")
  vim.fn.writefile({
    "package example;",
    "public class Main {",
    "    public static void main(String[] args) {",
    "        Greeter greeter = new Greeter();",
    "        System.out.println(greeter.message());",
    "    }",
    "}",
  }, project_root .. "/src/main/java/example/Main.java")
  vim.fn.writefile({
    "package example;",
    "public class Greeter {",
    '    public String message() { return "hello"; }',
    "}",
  }, project_root .. "/src/main/java/example/Greeter.java")
end

vim.opt.rtp:append(config_root)
local lazy_root = vim.fn.stdpath("data") .. "/lazy"
for _, plugin in ipairs({
  "mason.nvim",
  "nvim-lspconfig",
  "nvim-jdtls",
  "nvim-dap",
  "nvim-navic",
  "blink.cmp",
  "spring-boot.nvim",
}) do
  vim.opt.rtp:append(lazy_root .. "/" .. plugin)
end
require("mason").setup()
require("nvim-navic").setup()
vim.cmd.cd(vim.fn.fnameescape(project_root))
vim.cmd.edit(vim.fn.fnameescape(project_root .. "/src/main/java/example/Main.java"))

local started = vim.uv.hrtime()
local function elapsed()
  return math.floor((vim.uv.hrtime() - started) / 1e6)
end
local result = { exits = {} }
local original_start = vim.lsp.start
vim.lsp.start = function(config, options)
  local previous_exit = config.on_exit
  config.on_exit = function(code, signal, client_id)
    result.exits[config.name] = { code = code, signal = signal }
    if previous_exit then
      previous_exit(code, signal, client_id)
    end
  end
  if config.name == "jdtls" then
    result.launch_ms = elapsed()
    result.launcher = config.cmd_env.JAVA_HOME
    for index, argument in ipairs(config.cmd) do
      if argument == "-data" then
        result.workspace = config.cmd[index + 1]
      end
      if argument == "-configuration" then
        result.configuration = config.cmd[index + 1]
      end
    end
    local previous_status = config.handlers["language/status"]
    config.handlers["language/status"] = function(err, status, context)
      if status and status.type == "ServiceReady" and result.ready_ms == nil then
        result.ready_ms = elapsed()
      end
      if previous_status then
        previous_status(err, status, context)
      end
    end
    local previous_diagnostics = config.handlers["textDocument/publishDiagnostics"]
      or vim.lsp.handlers["textDocument/publishDiagnostics"]
    config.handlers["textDocument/publishDiagnostics"] = function(err, diagnostics, context)
      if diagnostics and diagnostics.uri == vim.uri_from_bufnr(0) and result.diagnostics_ms == nil then
        result.diagnostics_ms = elapsed()
      end
      if previous_diagnostics then
        previous_diagnostics(err, diagnostics, context)
      end
    end
  end
  return original_start(config, options)
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    result[client.name .. "_attach_ms"] = elapsed()
  end,
})

local spring_spec = dofile(config_root .. "/lua/plugins/lsp/spring_boot.lua")[1]
require("spring_boot").setup(spring_spec.opts())
dofile(config_root .. "/lua/plugins/lsp/jdtls.lua")[1].config()
vim.bo.filetype = "java"
assert(
  vim.wait(60000, function()
    return result.ready_ms ~= nil
  end, 20),
  "JDTLS did not become ready within 60 seconds"
)

local client = assert(vim.lsp.get_clients({ name = "jdtls" })[1])
local commands = client.server_capabilities.executeCommandProvider.commands
assert(vim.tbl_contains(commands, "vscode.java.startDebugSession"), "The Java debug extension should be available")
assert(vim.tbl_contains(commands, "sts.java.addClasspathListener"), "The Spring extension should be available")
local response = assert(client:request_sync("textDocument/definition", {
  textDocument = { uri = vim.uri_from_bufnr(0) },
  position = { line = 4, character = 36 },
}, 15000, 0))
assert(not response.err, vim.inspect(response.err))
local location = response.result and (response.result[1] or response.result)
local target = location and (location.uri or location.targetUri)
assert(target and target:match("/example/Greeter.java$"), "Semantic navigation should resolve a method in another file")
result.definition_ms = elapsed()
assert(
  vim.wait(15000, function()
    return result["spring-boot_attach_ms"] ~= nil
  end, 20),
  "The Spring language server should attach"
)
assert(
  vim.wait(15000, function()
    return result.diagnostics_ms ~= nil
  end, 20),
  "Initial document diagnostics should finish before testing normal shutdown"
)
local symbols = assert(client:request_sync("workspace/symbol", { query = "Greeter" }, 30000, 0))
assert(not symbols.err, vim.inspect(symbols.err))
assert(
  vim.iter(symbols.result or {}):any(function(symbol)
    return symbol.name == "Greeter"
  end),
  "Workspace symbol search should find the indexed Java class"
)
result.symbols_ms = elapsed()

local shutdown_started = vim.uv.hrtime()
for _, active in ipairs(vim.lsp.get_clients()) do
  active:stop()
end
assert(
  vim.wait(15000, function()
    return #vim.lsp.get_clients() == 0
  end, 20),
  "Language servers should stop cleanly"
)
result.shutdown_ms = math.floor((vim.uv.hrtime() - shutdown_started) / 1e6)
print("JDTLS_BENCH " .. vim.json.encode(result))
for name, exit in pairs(result.exits) do
  assert(exit.code == 0 and exit.signal == 0, name .. " should exit without a signal or failure")
end
local log = table.concat(vim.fn.readfile(result.workspace .. "/.metadata/.log"), "\n")
assert(
  not log:find("com.microsoft.java.test.plugin", 1, true),
  "Disabled Java Test bundles must not leak into the new configuration"
)
assert(not log:find("ObjectNotFoundException", 1, true), "The disposable workspace must remain healthy")
