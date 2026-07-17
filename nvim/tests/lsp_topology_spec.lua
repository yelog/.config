local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))

local function read(relative_path)
  return table.concat(vim.fn.readfile(config_root .. "/" .. relative_path), "\n")
end

local lsp = read("lua/plugins/lsp/lsp.lua")
local jdtls = read("lua/plugins/lsp/jdtls.lua")
local treesitter = read("lua/plugins/lsp/treesitter.lua")

assert(lsp:find("vim.lsp.config('*'", 1, true), "All ordinary LSP servers should inherit shared attachment behavior")
assert(
  lsp:find('vim.fn.stdpath("data") .. "/mason/packages/vue-language-server', 1, true),
  "Vue TypeScript plugin path should be portable"
)
assert(lsp:find("@vue/typescript-plugin", 1, true), "vtsls should load the Vue TypeScript plugin")
assert(lsp:find("'typescriptreact', 'vue'", 1, true), "vtsls should attach to Vue files")
assert(not lsp:find("hybridMode = false", 1, true), "Vue language server should stay in hybrid mode")
assert(not lsp:find("vim.lsp.config('vue_ls', {", 1, true), "vue_ls should keep its default Vue-only filetypes")
assert(
  not lsp:find("vim.lsp.config('rust_analyzer'", 1, true),
  "rust-analyzer should use its default diagnostics configuration"
)
assert(lsp:find('exclude = { "jdtls", "copilot" }', 1, true), "Mason must not auto-enable a second Copilot LSP client")

assert(jdtls:find('require("custom.java_runtime")', 1, true), "JDTLS should use validated Java runtime discovery")
assert(jdtls:find("cmd_env", 1, true), "JDTLS should receive an explicit launcher JAVA_HOME")
assert(
  jdtls:find("vscode-spring-boot-tools", 1, true) or lsp:find("vscode-spring-boot-tools", 1, true),
  "Mason should ensure Spring Boot language tools"
)

assert(treesitter:find('"rust"', 1, true), "Treesitter should install the Rust parser")
assert(treesitter:find('"toml"', 1, true), "Treesitter should install the TOML parser")

print("lsp-topology-tests: ok")
