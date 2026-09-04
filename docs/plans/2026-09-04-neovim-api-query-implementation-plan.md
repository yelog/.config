# Neovim API Query Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace `zerochae/endpoint.nvim` with an independently tested, multi-language endpoint index that searches source APIs through Snacks and materializes executable Kulala requests.

**Architecture:** Build a small `api_query` core around normalized endpoint fragments and a route composition graph. Tree-sitter providers perform framework-specific extraction, optional LSP resolvers enrich ambiguous Java/type relationships, Snacks presents results, and Kulala remains the only request executor.

**Tech Stack:** Lua, Neovim 0.11+ APIs, `vim.system`, Tree-sitter, Snacks picker, Kulala, JDTLS/Spring Boot Language Server, plain headless Neovim tests.

---

## Constraints

- Follow `docs/plans/2026-09-04-neovim-api-query-design.md` for product behavior and framework semantics.
- Do not modify `/Users/yelog/.local/share/nvim/lazy/endpoint.nvim`; it is reference material only.
- Do not add a second HTTP client or picker dependency.
- Do not execute target project code during static discovery.
- Do not store secrets in index/cache/config.
- Do not remove `endpoint.nvim` until the replacement passes framework fixtures and clean-install configuration checks.
- Do not commit unless explicitly requested.

### Task 1: Establish the Endpoint Model and Provider Contract

**Files:**
- Create: `nvim/lua/api_query/model.lua`
- Create: `nvim/lua/api_query/providers/init.lua`
- Create: `nvim/tests/api_query_model_spec.lua`

**Step 1: Write failing model tests**

Cover normalized uppercase methods, slash joining, duplicate-preserving parameter lists, stable IDs, deterministic sorting, confidence values, source locations and invalid provider registration.

**Step 2: Run the test and verify it fails**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_model_spec.lua" "+qa!"
```

Expected: failure because `api_query.model` does not exist.

**Step 3: Implement the minimal pure model API**

Expose:

```lua
model.endpoint(raw)
model.parameter(raw)
model.join_path(...)
model.stable_id(endpoint)
model.compare(left, right)

providers.register(provider)
providers.get(id)
providers.list()
```

Reject malformed locations and unknown confidence/source values early. Keep this module independent of buffers, LSP, Snacks and filesystem APIs.

**Step 4: Run the test and verify it passes**

Expected: `api-query-model-tests: ok`.

**Step 5: Check the scoped diff**

```bash
git diff --check
stylua --check nvim/lua/api_query/model.lua nvim/lua/api_query/providers/init.lua nvim/tests/api_query_model_spec.lua
```

### Task 2: Build Framework Detection and Candidate Scanning

**Files:**
- Create: `nvim/lua/api_query/roots.lua`
- Create: `nvim/lua/api_query/detector.lua`
- Create: `nvim/lua/api_query/scanner.lua`
- Create: `nvim/tests/api_query_detection_spec.lua`

**Step 1: Write failing fixture tests**

Use temporary `pom.xml`, `build.gradle`, `pyproject.toml`, `requirements.txt`, `go.mod`, `package.json` and lockfiles. Assert framework ID, language, major version, project root and exclusion of `.git`, `node_modules`, `vendor`, `target`, `build` and `dist`.

**Step 2: Run the failing test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_detection_spec.lua" "+qa!"
```

**Step 3: Implement bounded metadata parsing and async scanning**

Use `vim.fs.root`/`vim.fs.find` for root and manifest discovery. Use `vim.system({ "rg", ... })` with argument arrays, cancellation and stderr propagation for candidates. Never interpolate project paths into a shell string.

**Step 4: Verify detection and scanner error paths**

Expected: `api-query-detection-tests: ok`, including missing `rg`, cancelled process and malformed manifest cases.

### Task 3: Add Tree-sitter Frontends and Constant Evaluation

**Files:**
- Create: `nvim/lua/api_query/treesitter.lua`
- Create: `nvim/lua/api_query/constants.lua`
- Create: `nvim/lua/api_query/imports.lua`
- Create: `nvim/tests/api_query_frontend_spec.lua`
- Modify: `nvim/lua/plugins/lsp/treesitter.lua`

**Step 1: Write failing language frontend tests**

Test Java annotations and string constants, Python decorators/import aliases, Go calls and string constants, JavaScript/TypeScript ESM/CJS exports, object literals and template strings. Include syntax-error fixtures and unresolved dynamic expressions.

**Step 2: Run the failing test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_frontend_spec.lua" "+qa!"
```

**Step 3: Implement parser access and bounded evaluation**

Support literals, literal arrays/objects, immutable references and pure string concatenation only. Return `{ value, evidence, unresolved }`; never execute source expressions.

**Step 4: Install required parser declarations**

Add `python` and `go` to the existing Tree-sitter installation and startup lists. Keep Java, JavaScript and TypeScript behavior unchanged.

**Step 5: Verify parsers and formatting**

Run the frontend test and `stylua --check` on all touched Lua files.

### Task 4: Implement Route Composition Graph and Index

**Files:**
- Create: `nvim/lua/api_query/graph.lua`
- Create: `nvim/lua/api_query/index.lua`
- Create: `nvim/lua/api_query/diagnostics.lua`
- Create: `nvim/tests/api_query_index_spec.lua`

**Step 1: Write failing graph tests**

Cover nested prefix composition, one router mounted more than once, callback scopes, module reachability, middleware inheritance, graph cycles, deleted files, stable ordering and duplicate endpoint handling.

**Step 2: Run the failing test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_index_spec.lua" "+qa!"
```

**Step 3: Implement fragments and generations**

Represent controller, route, mount, include, schema and middleware as source-backed fragments. The index owns file summaries and graph generations; providers do not mutate global state.

**Step 4: Add incremental invalidation tests**

Assert one changed route file does not reparse unrelated files, while a changed mount/include file recomputes dependent endpoints.

**Step 5: Verify the test passes**

Expected: `api-query-index-tests: ok`.

### Task 5: Implement Java Providers

**Files:**
- Create: `nvim/lua/api_query/providers/java/spring.lua`
- Create: `nvim/lua/api_query/providers/java/jaxrs.lua`
- Create: `nvim/tests/api_query_java_spec.lua`
- Create: `nvim/tests/fixtures/api-query/java/`

**Step 1: Write failing Spring and JAX-RS fixtures**

Cover class/method mapping combinations, arrays, `RequestMapping.method`, inherited/interface declarations, static constants/imports, body DTO recursion, multipart, `javax`/`jakarta`, `@BeanParam`, duplicate query/header entries and unresolved expressions.

**Step 2: Run the failing test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_java_spec.lua" "+qa!"
```

**Step 3: Implement Spring extraction**

Use annotation fully qualified identity where imports are resolvable. Emit controller/route/parameter/body fragments and preserve all class-path × method-path × HTTP-method combinations.

**Step 4: Implement JAX-RS extraction**

Support standard path/method/parameter annotations and bounded `@BeanParam` expansion for both package namespaces.

**Step 5: Verify Java fixtures**

Expected: `api-query-java-tests: ok` with explicit assertions for final paths and source positions.

### Task 6: Implement Python Providers

**Files:**
- Create: `nvim/lua/api_query/providers/python/fastapi.lua`
- Create: `nvim/lua/api_query/providers/python/flask.lua`
- Create: `nvim/lua/api_query/providers/python/django.lua`
- Create: `nvim/tests/api_query_python_spec.lua`
- Create: `nvim/tests/fixtures/api-query/python/`

**Step 1: Write failing framework fixtures**

Cover FastAPI `APIRouter/include_router/Annotated/Pydantic`, Flask Blueprint/register/add_url_rule/MethodView, and Django path/re_path/include/function/class views. Include duplicate mounts and application-factory composition.

**Step 2: Run the failing test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_python_spec.lua" "+qa!"
```

**Step 3: Implement provider-specific extraction**

FastAPI declared parameters receive high confidence. Flask/Django command-style `request` accesses receive `source = "accessed"`; do not mark them required without declaration evidence.

**Step 4: Verify Python fixtures**

Expected: `api-query-python-tests: ok`.

### Task 7: Implement Go Providers

**Files:**
- Create: `nvim/lua/api_query/providers/go/net_http.lua`
- Create: `nvim/lua/api_query/providers/go/gin.lua`
- Create: `nvim/lua/api_query/providers/go/chi.lua`
- Create: `nvim/tests/api_query_go_spec.lua`
- Create: `nvim/tests/fixtures/api-query/go/`

**Step 1: Write failing Go fixtures**

Cover Go 1.22 ServeMux patterns, old method switch, Gin nested groups and binding tags, Chi Route/Group/Mount/With callback scopes, registration functions receiving router parameters and unresolved custom wrappers.

**Step 2: Run the failing test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_go_spec.lua" "+qa!"
```

**Step 3: Implement provider extraction and path grammars**

Treat receiver type as confirmed only when constructor/import/parameter flow proves router identity. Method-name-only matches remain candidates, not endpoints.

**Step 4: Verify Go fixtures**

Expected: `api-query-go-tests: ok`.

### Task 8: Implement Node.js and TypeScript Providers

**Files:**
- Create: `nvim/lua/api_query/providers/node/express.lua`
- Create: `nvim/lua/api_query/providers/node/fastify.lua`
- Create: `nvim/lua/api_query/providers/node/nest.lua`
- Create: `nvim/tests/api_query_node_spec.lua`
- Create: `nvim/tests/fixtures/api-query/node/`

**Step 1: Write failing framework fixtures**

Cover Express 4/5 Router, `route()` chains, callback arrays, CJS/ESM and multiple mounts; Fastify route objects, shorthand, spread options and nested plugin prefixes; Nest controller/module reachability, global prefix and parameter decorators.

**Step 2: Run the failing test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_node_spec.lua" "+qa!"
```

**Step 3: Implement version-aware providers**

Read detected major versions instead of assuming current framework syntax. Preserve Fastify host/version constraints and Nest policy types separately.

**Step 4: Verify Node fixtures**

Expected: `api-query-node-tests: ok`.

### Task 9: Build the Snacks Picker and Public Commands

**Files:**
- Create: `nvim/lua/api_query/config.lua`
- Create: `nvim/lua/api_query/picker.lua`
- Create: `nvim/lua/api_query/init.lua`
- Create: `nvim/lua/plugins/panel/api-query.lua`
- Create: `nvim/tests/api_query_picker_spec.lua`
- Modify: `nvim/lua/key-map.lua`

**Step 1: Write failing facade and action tests**

Stub Snacks and assert command parsing, sorting, preview data, source jump, copy actions, empty state, scan cancellation and diagnostics behavior.

**Step 2: Run the failing test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_picker_spec.lua" "+qa!"
```

**Step 3: Implement commands**

Register `ApiQuery`, `ApiQueryCurrent`, `ApiQueryRefresh`, `ApiQueryDiagnostics` and `ApiQueryFrameworks`. `<D-S-i>` calls `require("api_query").open()`; keep `:Endpoint` temporarily available during migration.

**Step 4: Implement picker actions**

Use Snacks directly. Do not add Telescope/fzf-lua adapters in this phase. Confirm defaults to source navigation; request actions are added in Task 10.

**Step 5: Verify picker tests and config startup**

```bash
nvim --headless "+lua require('api_query').setup()" "+qa!"
```

Expected: clean exit without opening or scanning a project.

### Task 10: Materialize Kulala Requests Safely

**Files:**
- Create: `nvim/lua/api_query/request.lua`
- Create: `nvim/tests/api_query_request_spec.lua`
- Modify: `nvim/lua/api_query/picker.lua`

**Step 1: Write failing request tests**

Cover base URL joining, `{id}`/`:id`/`<id>` placeholders, repeated query/header values, JSON/form/multipart bodies, Services URL priority, fallback comments, unsafe method confirmation, unresolved placeholders and secret variable preservation.

**Step 2: Run the failing test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_request_spec.lua" "+qa!"
```

**Step 3: Implement pure draft generation**

Expose:

```lua
request.materialize(endpoint, context)
request.open(endpoint, context)
request.run(endpoint, context)
```

`materialize` is pure and returns lines plus unresolved variables. `open` creates an `http` scratch buffer only after success. `run` delegates to Kulala and refuses unresolved path placeholders.

**Step 4: Connect picker actions**

Implement `e`, `r`, `f`, `y`, `c` and `o`. Unsafe methods require confirmation even when the picker selection was confirmed.

**Step 5: Verify request tests**

Expected: `api-query-request-tests: ok`.

### Task 11: Add Incremental Refresh and Optional Persistent Cache

**Files:**
- Create: `nvim/lua/api_query/cache.lua`
- Create: `nvim/tests/api_query_cache_spec.lua`
- Modify: `nvim/lua/api_query/index.lua`
- Modify: `nvim/lua/api_query/init.lua`

**Step 1: Write failing cache tests**

Cover atomic writes, corrupt cache, schema version mismatch, source fingerprint mismatch, no secret/environment values, per-root isolation and debounce behavior.

**Step 2: Run the failing test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/api_query_cache_spec.lua" "+qa!"
```

**Step 3: Implement cache and autocmds**

Store under `stdpath("cache")/api-query/`. Register one augroup for `BufWritePost` and `FileChangedShellPost`; setup must be idempotent.

**Step 4: Verify cache and incremental behavior**

Expected: `api-query-cache-tests: ok`.

### Task 12: Remove endpoint.nvim and Verify Clean Installation

**Files:**
- Delete: `nvim/lua/plugins/panel/endpoint.lua`
- Modify: `nvim/lazy-lock.json`
- Modify: `nvim/tests/config_correctness_spec.lua`
- Create: `nvim/tests/api_query_integration_spec.lua`

**Step 1: Add a failing migration test**

Assert no active config references `zerochae/endpoint.nvim`, `require("endpoint")`, `:Endpoint` or the old lock entry. Assert `<D-S-i>` opens `api_query` and Kulala remains the only HTTP client.

**Step 2: Run all API query tests before removal**

```bash
for test in /Users/yelog/.config/nvim/tests/api_query_*_spec.lua; do nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile ${test}" "+qa!" || exit 1; done
```

Expected: all provider, index, picker and request tests pass; migration assertion still fails.

**Step 3: Remove the dead plugin spec and lock entry**

Do not delete the local plugin installation directory manually. Lazy may clean it later; repository configuration must no longer depend on it.

**Step 4: Run the complete Neovim test suite**

```bash
for test in /Users/yelog/.config/nvim/tests/*_spec.lua; do nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile ${test}" "+qa!" || exit 1; done
```

Expected: every test exits 0.

**Step 5: Run final static verification**

```bash
stylua --check nvim/lua nvim/tests
git diff --check
git diff --stat
```

Expected: no formatting or whitespace errors and no unrelated files in the diff.

## Post-MVP Tasks

- Add DRF Router, Echo, Fiber v2/v3, Koa Router, Hapi, OpenFeign and Micronaut providers with the same fixture-first process.
- Add OpenAPI merge and Kulala operation linking.
- Add LSP enrichment for Java inheritance, Go receiver identity and TypeScript DTOs only after static provider metrics exist.
- Build a benchmark corpus and report route recall, final-path accuracy, handler linkage, parameter precision and unresolved-expression rate separately.
- Consider opt-in runtime probes only after a documented sandbox boundary and threat model are implemented.
