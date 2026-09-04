# Neovim API Query Spring Path Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the API Query Spring provider emit endpoints only for mapped methods, compose every method path with its owning controller path, and jump to the actual Java method declaration.

**Architecture:** Keep the existing `rg` candidate filter and endpoint index unchanged. Replace Spring's line-oriented declaration guessing with a Tree-sitter-backed declaration adapter that associates annotations with `class_declaration`, `interface_declaration`, `record_declaration`, and `method_declaration` nodes; retain a strict line parser only as degraded fallback when the Java parser is unavailable. Class mappings become prefixes only, while method mappings are the sole source of endpoints.

**Tech Stack:** Lua, Neovim 0.11+ APIs, Neovim Tree-sitter Java parser, plain headless Neovim tests, existing `api_query` model/index/picker.

---

## Constraints

- Preserve the `rg` candidate filtering in `nvim/lua/api_query/index.lua`; the fix must not return to reading every project file.
- Do not execute Java code, invoke Maven, or depend on JDTLS to discover routes.
- Do not emit a class-level `@RequestMapping` as an endpoint by itself.
- Emit an endpoint only when a Java method has a Spring mapping annotation.
- Treat an empty method mapping path as a valid endpoint at the controller root.
- Preserve all class-path x method-path x HTTP-method combinations.
- Keep `endpoint.declaration` on the method mapping annotation and `endpoint.handler` on the method name/declaration.
- Do not change JAX-RS behavior in this fix; create a separate task if the same structural defect is later confirmed there.
- Do not commit unless the user explicitly requests it.

## Success Criteria

- `AgreementController` contains `POST /agreement`, `POST /agreement/page`, and the other composed method endpoints, but no standalone `ANY /agreement` created from the class annotation.
- `ClientController.delete` is indexed as `ANY /client/delete`, not `ANY /delete`.
- Enter on `/client/delete` jumps to the `delete` method declaration rather than `@RequestMapping`, `@PreAuthorize`, or another annotation.
- Ordinary annotations such as `@Tag`, `@Operation`, `@PreAuthorize`, `@CacheEvict`, and `@Valid` never consume pending route state.
- Existing API Query tests pass.
- Scanning `moss-cloud` still returns in under 1 second on the current machine, with an aspirational target below 300 ms.

### Task 1: Capture the Two Production Regressions

**Files:**
- Create: `nvim/tests/api_query_spring_spec.lua`
- Reference only: `/Users/yelog/workspace/lenovo/moss/moss-cloud/moss-service-common/moss-service-common-server/src/main/java/com/lenovo/moss/service/common/server/controller/AgreementController.java`
- Reference only: `/Users/yelog/workspace/lenovo/moss/moss-cloud/moss-service-common/moss-service-common-server/src/main/java/com/lenovo/moss/service/common/server/controller/ClientController.java`

**Step 1: Add a self-contained Spring test harness**

Create the test file with the same runtime-path setup used by `nvim/tests/api_query_provider_spec.lua`. Add helpers that find an endpoint by method/path and assert that a path is absent:

```lua
local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local spring = require("api_query.providers.java.spring")

local function find_endpoint(items, method, path)
  for _, item in ipairs(items) do
    if item.path == path and vim.tbl_contains(item.methods or {}, method) then return item end
  end
end

local function assert_absent(items, path)
  for _, item in ipairs(items) do
    assert(item.path ~= path, "unexpected endpoint: " .. path)
  end
end
```

**Step 2: Add the AgreementController regression fixture**

Use a compact fixture that preserves the annotation ordering responsible for the bug:

```lua
local agreement_source = table.concat({
  "@RestController",
  '@RequestMapping("/agreement")',
  '@Tag(name = "协议管理")',
  "public class AgreementController {",
  '  @Operation(summary = "分页查询")',
  '  @PostMapping("/page")',
  '  @PreAuthorize("hasAuthority(\'agreement\')")',
  "  public ResultData<?> page(@RequestBody Query query) {}",
  "",
  "  @PostMapping",
  "  @CacheEvict(allEntries = true)",
  "  public ResultData<?> create(@RequestBody Create body) {}",
  "}",
}, "\n")

local agreement = spring.extract({ source = agreement_source }, { path = "/tmp/AgreementController.java" })
assert(#agreement == 2, "class mappings and ordinary annotations must not create endpoints")
assert(find_endpoint(agreement, "POST", "/agreement/page"), "method path should include controller prefix")
assert(find_endpoint(agreement, "POST", "/agreement"), "empty method path should resolve to controller root")
assert_absent(agreement, "/page")
assert_absent(agreement, "/")
```

Do not assert that `/agreement` is entirely absent: `@PostMapping` without a path makes `POST /agreement` a legitimate method endpoint. Instead, assert there is no class-derived `ANY /agreement` and that the endpoint handler is the `create` method.

**Step 3: Add the ClientController regression fixture**

```lua
local client_source = table.concat({
  "@RestController",
  '@RequestMapping("/client")',
  '@PreAuthorize("hasAuthority(\'client\')")',
  "public class ClientController {",
  '  @RequestMapping("/delete")',
  "  public ResultData<?> delete(String clientId) {}",
  "",
  '  @PostMapping("/batchUpdClientVer")',
  "  public ResultData<?> batchUpdate(@RequestBody Request request) {}",
  "}",
}, "\n")

local client = spring.extract({ source = client_source }, { path = "/tmp/ClientController.java" })
assert(#client == 2, "only mapped methods should create endpoints")
assert(find_endpoint(client, "ANY", "/client/delete"), "RequestMapping should inherit the controller prefix")
assert(find_endpoint(client, "POST", "/client/batchUpdClientVer"), "PostMapping should inherit the controller prefix")
assert_absent(client, "/delete")
assert_absent(client, "/batchUpdClientVer")
```

**Step 4: Assert source locations**

Assert the declaration stays on the method mapping while the handler points to the method declaration:

```lua
local delete = assert(find_endpoint(client, "ANY", "/client/delete"))
assert(delete.declaration.line == 5, "declaration should point to the method mapping")
assert(delete.handler.line == 6, "handler should point to the Java method")

local create = assert(find_endpoint(agreement, "POST", "/agreement"))
assert(create.declaration.line == 10, "empty-path mapping should retain its annotation location")
assert(create.handler.line == 12, "ordinary annotations must not become the handler")
```

**Step 5: Run the regression test and verify it fails for the known reasons**

Run:

```bash
nvim --headless -u NONE \
  '+set rtp+=/Users/yelog/.config/nvim' \
  '+luafile /Users/yelog/.config/nvim/tests/api_query_spring_spec.lua' \
  '+qa!'
```

Expected before implementation: FAIL because the provider emits class-level endpoints, loses controller prefixes after annotations with parentheses, and points handlers at annotation lines.

### Task 2: Add a Java Declaration Adapter

**Files:**
- Create: `nvim/lua/api_query/providers/java/declarations.lua`
- Modify: `nvim/lua/api_query/treesitter.lua`
- Test: `nvim/tests/api_query_spring_spec.lua`

**Step 1: Define a small provider-facing declaration contract**

The adapter should return syntax-backed declarations without Spring semantics:

```lua
---@class ApiQueryJavaAnnotation
---@field name string
---@field arguments string?
---@field text string
---@field line integer
---@field column integer

---@class ApiQueryJavaMethod
---@field name string
---@field line integer
---@field column integer
---@field signature string
---@field annotations ApiQueryJavaAnnotation[]

---@class ApiQueryJavaType
---@field kind "class"|"interface"|"record"
---@field name string
---@field line integer
---@field annotations ApiQueryJavaAnnotation[]
---@field methods ApiQueryJavaMethod[]
---@field types ApiQueryJavaType[]
```

Expose:

```lua
declarations.parse(text) -> types, error
```

The adapter must not know about `RequestMapping`, HTTP methods, endpoint models, or path joining.

**Step 2: Extend the Tree-sitter helper with source-node utilities**

In `nvim/lua/api_query/treesitter.lua`, retain `parse(text, language)` and add only the reusable primitives needed by the declaration adapter:

```lua
function M.node_text(node, source)
  return vim.treesitter.get_node_text(node, source)
end

function M.position(node)
  local row, column = node:start()
  return row + 1, column + 1
end
```

Do not add Spring-specific queries to this generic module.

**Step 3: Parse Java type declarations with Tree-sitter**

Use `vim.treesitter.query.parse("java", query)` and `vim.treesitter.get_string_parser`. Capture type declarations and their bodies:

```scheme
[
  (class_declaration name: (identifier) @type.name body: (class_body) @type.body)
  (interface_declaration name: (identifier) @type.name body: (interface_body) @type.body)
  (record_declaration name: (identifier) @type.name body: (class_body) @type.body)
] @type.declaration
```

If the installed grammar uses a different record body node, inspect the parser tree and adjust the query to the actual grammar. Do not silently drop record support after declaring it in the contract.

Only include top-level and nested type declarations once. Associate a method with its nearest owning type so nested controllers cannot inherit the outer controller path.

**Step 4: Parse only real method declarations**

Collect `method_declaration` nodes from each type body. Do not treat these as methods:

- `constructor_declaration`
- `field_declaration`
- `annotation_type_declaration`
- lambda expressions
- method invocations
- annotation argument lists

Read the method name through the `name:` field and preserve the complete declaration text as `signature` for parameter extraction.

**Step 5: Associate annotations by AST ownership**

For each type or method declaration, inspect the declaration's `modifiers` child and collect only direct `annotation` and `marker_annotation` children. This naturally allows ordinary annotations between a route annotation and the declaration without consuming state.

Normalize annotation names to their final identifier while retaining raw text:

```text
org.springframework.web.bind.annotation.GetMapping -> GetMapping
GetMapping -> GetMapping
```

Extract `arguments` from the annotation argument-list node when present. Preserve multiline argument text unchanged so the Spring mapping parser can handle it independently.

**Step 6: Add declaration adapter tests before connecting Spring**

Add assertions to `nvim/tests/api_query_spring_spec.lua` for:

- one class containing `RequestMapping` and `PreAuthorize` annotations;
- two methods with their own direct annotations;
- method names and line/column positions;
- a constructor excluded from `methods`;
- a nested class represented separately;
- multiline method signatures;
- multiline annotation arguments.

If the Java parser is missing, fail this adapter test with an actionable message rather than marking it passed:

```lua
assert(types, "Java Tree-sitter parser is required for Spring structural tests: " .. tostring(err))
```

**Step 7: Run the focused test**

Run the same `api_query_spring_spec.lua` command.

Expected at this point: declaration adapter assertions PASS; endpoint regression assertions still FAIL because Spring has not switched to the adapter.

### Task 3: Make Spring Extraction Declaration-Driven

**Files:**
- Modify: `nvim/lua/api_query/providers/java/spring.lua`
- Test: `nvim/tests/api_query_spring_spec.lua`
- Regression test: `nvim/tests/api_query_provider_spec.lua`

**Step 1: Separate annotation interpretation from source traversal**

Refactor the current `mapping(line)` into a function that accepts an annotation object:

```lua
local function mapping(annotation)
  local name = annotation.name
  local args = annotation.arguments
  -- Return nil for Tag, Operation, PreAuthorize, CacheEvict, Valid, etc.
  -- Return { paths, methods, name, location } for Spring mapping annotations.
end
```

Keep the supported mapping set explicit:

```lua
local shortcut_methods = {
  GetMapping = "GET",
  PostMapping = "POST",
  PutMapping = "PUT",
  PatchMapping = "PATCH",
  DeleteMapping = "DELETE",
  HeadMapping = "HEAD",
  OptionsMapping = "OPTIONS",
}
```

`RequestMapping` without `method` remains `ANY`. A shortcut mapping without a path returns `paths = { "" }`.

**Step 2: Parse annotation paths and methods without line assumptions**

Support these forms:

```java
@GetMapping("/users")
@GetMapping(value = "/users")
@GetMapping(path = "/users")
@GetMapping({"/users", "/members"})
@RequestMapping(path = "/users", method = RequestMethod.GET)
@RequestMapping(method = {RequestMethod.GET, RequestMethod.POST})
```

Retain the current bounded string extraction for this task, but consume the complete multiline annotation text supplied by Tree-sitter. Do not add arbitrary Java expression evaluation here; unresolved constants remain a later constants-provider concern.

**Step 3: Extract controller prefixes from type annotations only**

For every parsed Java type:

```lua
local class_paths = { "" }
for _, annotation in ipairs(type_decl.annotations) do
  local route = mapping(annotation)
  if route and route.name == "RequestMapping" then
    class_paths = route.paths
  end
end
```

Do not emit endpoints in this phase. `@RestController` and `@Controller` identify controller intent but do not themselves define paths.

For the first implementation, scan types that have `@RestController`, `@Controller`, or a class-level `@RequestMapping`. Avoid broadening to custom composed controller annotations until there is a fixture and metadata-resolution design.

**Step 4: Emit endpoints only from method mappings**

For every method, collect all recognized mapping annotations. For each method route, compute:

```lua
for _, class_path in ipairs(class_paths) do
  for _, method_path in ipairs(route.paths) do
    result[#result + 1] = endpoint(
      filename,
      route,
      class_path,
      method_path,
      params,
      body,
      route.line,
      method.line,
      method.column,
      method.name
    )
  end
end
```

A class with only `@RequestMapping` and no mapped methods must produce zero endpoints.

**Step 5: Fix endpoint locations and handler name**

Update the endpoint constructor so that:

```lua
declaration = location(file, route.line, route.column)
handler = location(file, method.line, method.column)
handler_name = method.name
```

This lets the existing picker search by method name and makes Enter jump to the method declaration.

**Step 6: Keep parameter extraction bounded**

Reuse the current parameter extraction behavior against the complete Tree-sitter method signature. Preserve duplicate parameters and body detection. Do not expand DTO schemas as part of this bug fix.

Replace naive comma splitting only if a focused test demonstrates breakage for generic parameter types or nested annotation arguments. If needed, add a small delimiter-depth splitter rather than a Java parser inside the Spring provider.

**Step 7: Run focused tests**

Run:

```bash
nvim --headless -u NONE \
  '+set rtp+=/Users/yelog/.config/nvim' \
  '+luafile /Users/yelog/.config/nvim/tests/api_query_spring_spec.lua' \
  '+qa!'

nvim --headless -u NONE \
  '+set rtp+=/Users/yelog/.config/nvim' \
  '+luafile /Users/yelog/.config/nvim/tests/api_query_provider_spec.lua' \
  '+qa!'
```

Expected: both print their `...tests: ok` marker and exit 0.

### Task 4: Add a Strict Degraded Fallback

**Files:**
- Create: `nvim/lua/api_query/providers/java/fallback.lua`
- Modify: `nvim/lua/api_query/providers/java/spring.lua`
- Test: `nvim/tests/api_query_spring_spec.lua`

**Step 1: Make parser availability injectable for tests**

Allow `spring.extract` to use a supplied declaration parser without changing normal callers:

```lua
local declaration_parser = context.declaration_parser or declarations.parse
local types, parse_error = declaration_parser(text)
```

This provides a deterministic way to exercise fallback behavior without uninstalling the Java parser.

**Step 2: Define fallback behavior explicitly**

Expose:

```lua
fallback.parse(text) -> types, diagnostics
```

The fallback must produce the same declaration contract as `declarations.parse`, but may support fewer Java constructs. It must never return an endpoint directly.

**Step 3: Implement a strict lexical state machine**

Track:

- block comments and line comments;
- string and character literals;
- brace depth;
- parenthesis depth for multiline annotations and signatures;
- pending direct annotations;
- current type stack;
- declaration start line.

Only consume pending annotations when an explicit type or method declaration is recognized. Ordinary annotations remain attached to the next declaration but are ignored later by Spring unless their names are mapping annotations.

At minimum recognize:

```text
[modifiers] class Name
[modifiers] interface Name
[modifiers] record Name(...)
[modifiers] ReturnType methodName(...)
```

Do not classify a line beginning with `@`, a constructor, control statement, lambda, field initializer, or method invocation as a method declaration.

**Step 4: Prefer omission over false endpoints**

When fallback cannot confidently identify annotation ownership or declaration boundaries:

- do not emit the questionable method;
- return a diagnostic describing the file and unsupported structure;
- never reinterpret a class mapping as a method mapping.

False negatives in degraded mode are safer than executable false endpoints.

**Step 5: Add fallback regression tests**

Inject a parser that returns an error:

```lua
local context = {
  source = client_source,
  declaration_parser = function() return nil, "java parser unavailable" end,
}
local fallback_client = spring.extract(context, { path = "/tmp/ClientController.java" })
```

Assert the fallback still returns `/client/delete`, does not return `/client` or `/delete`, and points the handler at the method declaration.

Add a fixture containing annotation arguments, a constructor, a lambda field, and a normal method invocation; assert none become endpoints.

**Step 6: Run focused tests**

Expected: AST and fallback variants both pass the same endpoint/path/location assertions.

### Task 5: Cover Spring Mapping Semantics and Scope Boundaries

**Files:**
- Modify: `nvim/tests/api_query_spring_spec.lua`
- Modify if required: `nvim/lua/api_query/providers/java/spring.lua`

**Step 1: Add path/method Cartesian-product coverage**

Fixture:

```java
@RestController
@RequestMapping({"/v1/users", "/v2/users"})
class UsersController {
  @RequestMapping(path = {"/{id}", "/by-id/{id}"}, method = {RequestMethod.GET, RequestMethod.HEAD})
  User get(String id) { return null; }
}
```

Assert eight endpoints: 2 class paths x 2 method paths x 2 HTTP methods. Assert stable ordering only after passing through the index/model sorter; provider-local result order need not become a public contract.

**Step 2: Add empty-path semantics**

Cover:

```java
@RequestMapping("/agreement")
class AgreementController {
  @GetMapping
  Object get() { return null; }
}
```

Assert exactly `GET /agreement`.

**Step 3: Add multiple-controller isolation**

Put two top-level controllers in one fixture and assert their prefixes do not leak:

```text
GET /first/status
POST /second/create
```

**Step 4: Add nested-type isolation**

Create an outer controller and an inner controller with distinct mappings. Assert each method uses its nearest owning type path and never composes both paths unless explicit Spring semantics require it.

**Step 5: Add interface coverage**

Add a mapped interface method and assert it is indexed with the interface-level prefix. Do not implement inherited annotation resolution between separate files in this task; document that as a future semantic enrichment.

**Step 6: Add non-endpoint declarations**

Assert zero endpoints from:

- class-level mapping without mapped methods;
- constructors;
- private helpers without mapping annotations;
- methods with only `@Operation` or `@PreAuthorize`;
- fields initialized by calls or lambdas.

**Step 7: Run the focused Spring suite**

Expected: `api-query-spring-tests: ok`.

### Task 6: Validate the Real moss-cloud Project

**Files:**
- No source changes expected
- Runtime target: `/Users/yelog/workspace/lenovo/moss/moss-cloud`

**Step 1: Print AgreementController endpoints**

Run a headless provider extraction script against the real file and print method, path, declaration line, handler line, and handler name.

Expected entries include:

```text
POST /agreement/page
POST /agreement
PUT /agreement
GET /agreement/active
POST /agreement/{id}/activate
GET /agreement/{id}
GET /agreement/nextVersion
GET /agreement/codes
```

Expected absent entry:

```text
ANY /agreement
```

The path `/agreement` may appear for POST and PUT because those are real empty-path method mappings; absence is specifically about a synthetic class-level `ANY` endpoint.

**Step 2: Print ClientController endpoints**

Expected entries include:

```text
ANY /client/page
ANY /client/selectClientUpdateJarVer
ANY /client/selectDistinctClientList
ANY /client/selectLines
ANY /client/getScanGroupList
ANY /client/update
ANY /client/add
ANY /client/delete
ANY /client/clearMac
ANY /client/batchAddClientIdProcess
POST /client/batchUpdClientVer
```

Expected absent entries include `/client` as a standalone class endpoint and every unprefixed method path such as `/delete`.

**Step 3: Benchmark the full index**

Run:

```bash
nvim --headless -u NONE \
  --cmd 'set rtp+=/Users/yelog/.config/nvim' \
  --cmd 'lua local uv=vim.uv or vim.loop; local index=require("api_query.index"); local start=uv.hrtime(); local result=index.scan_root(vim.fn.getcwd(), { exclude={".git","node_modules","vendor","target","build","dist"} }); print(string.format("scan_seconds=%.3f endpoints=%d files=%d", (uv.hrtime()-start)/1e9, #result.endpoints, vim.tbl_count(result.files)))' \
  --cmd 'qa!'
```

Working directory:

```text
/Users/yelog/workspace/lenovo/moss/moss-cloud
```

Acceptance threshold: less than 1 second on the current machine. Record the endpoint count change and explain it: removal of synthetic class endpoints may lower the count, while correct path composition should not duplicate methods.

**Step 4: Perform an interactive Neovim smoke test**

Restart Neovim so the edited Lua modules are reloaded, open `moss-cloud`, and press `<D-S-i>`.

Verify:

1. Searching `agreement` shows real method endpoints with `/agreement` prefixes.
2. There is no `ANY /agreement` entry that jumps to the class mapping.
3. Searching `/client/delete` returns the ClientController method.
4. Pressing Enter jumps to `public ResultData<String> delete(...)`.
5. Picker opening remains effectively immediate.

### Task 7: Run Regression and Static Verification

**Files:**
- Verify all touched files

**Step 1: Run all API Query tests**

```bash
for test in /Users/yelog/.config/nvim/tests/api_query_*_spec.lua; do
  nvim --headless -u NONE \
    '+set rtp+=/Users/yelog/.config/nvim' \
    "+luafile ${test}" \
    '+qa!' || exit 1
done
```

Expected: every API Query test exits 0.

**Step 2: Run the complete Neovim test suite**

```bash
for test in /Users/yelog/.config/nvim/tests/*_spec.lua; do
  nvim --headless -u NONE \
    '+set rtp+=/Users/yelog/.config/nvim' \
    "+luafile ${test}" \
    '+qa!' || exit 1
done
```

Expected: all tests unrelated to environment-only dependencies pass. If `jb_codelens_spec.lua` still fails under `-u NONE` because the `jb` colorscheme is unavailable, report it as a pre-existing environment failure rather than changing this feature to accommodate it.

**Step 3: Verify normal configuration startup**

```bash
nvim --headless '+lua require("api_query").setup()' '+qa!'
```

Expected: clean exit without scanning a project or opening a picker.

**Step 4: Run formatting and whitespace checks**

```bash
stylua --check \
  nvim/lua/api_query/treesitter.lua \
  nvim/lua/api_query/providers/java/declarations.lua \
  nvim/lua/api_query/providers/java/fallback.lua \
  nvim/lua/api_query/providers/java/spring.lua \
  nvim/tests/api_query_spring_spec.lua

git diff --check -- \
  nvim/lua/api_query/treesitter.lua \
  nvim/lua/api_query/providers/java/declarations.lua \
  nvim/lua/api_query/providers/java/fallback.lua \
  nvim/lua/api_query/providers/java/spring.lua \
  nvim/tests/api_query_spring_spec.lua
```

Expected: no output from either checker. If `stylua` is unavailable, state that explicitly and do not claim formatting verification passed.

**Step 5: Inspect the scoped diff**

Confirm the implementation only changes the Spring parser, reusable Java declaration support, Tree-sitter helper, and focused tests. Do not modify the user's unrelated dirty files.

**Step 6: Commit only if explicitly requested**

Suggested commit message:

```text
fix(nvim): compose Spring controller endpoint paths
```

## Deferred Work

- Cross-file inheritance of Spring mappings from interfaces or base classes.
- Custom composed annotations resolved through annotation meta-annotations.
- Static constant evaluation for mapping paths beyond existing literal support.
- JAX-RS migration to the shared Java declaration adapter.
- Persistent API Query cache and buffer-write incremental indexing.

These are intentionally excluded because they are not required to fix the observed false class endpoints and missing controller prefixes.
