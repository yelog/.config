# Spring Property Navigation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Provide Spring-aware YAML assistance and make `gd` resolve static `${property.name}` references to project configuration keys.

**Architecture:** Load `spring-boot.nvim` independently of the Java-only JDTLS spec so the Spring Boot language server starts before `bootstrap*.yml` and `application*.yml` receive their FileType event. Keep `yamlls` attached for generic YAML features. A small local resolver handles project-defined placeholders before delegating to the existing LSP picker.

**Tech Stack:** Neovim 0.12, lazy.nvim, `JavaHello/spring-boot.nvim`, `vscode-spring-boot-tools`, `yaml-language-server`.

---

### Task 1: Load Spring Boot tools for Spring configuration files

**Files:**
- Create: `nvim/lua/plugins/lsp/spring_boot.lua`
- Modify: `nvim/lua/plugins/lsp/jdtls.lua:5-14`
- Modify: `nvim/tests/lsp_topology_spec.lua:8-36`

**Step 1: Add a topology assertion**

Assert that the standalone Spring plugin declares pre-FileType `BufReadPre`/`BufNewFile` events for `application` and `bootstrap` YAML files.

**Step 2: Run the topology test to verify it fails**

Run: `nvim --headless -u NONE -l nvim/tests/lsp_topology_spec.lua`

Expected: FAIL because no standalone Spring plugin spec exists.

**Step 3: Create the standalone plugin spec**

Configure `spring-boot.nvim` with the Spring configuration filename events and `opts = {}`. Keep it available to the JDTLS spec for extension bundles, without delaying it until Java is opened.

**Step 4: Run the topology test**

Run: `nvim --headless -u NONE -l nvim/tests/lsp_topology_spec.lua`

Expected: `lsp-topology-tests: ok`.

### Task 2: Resolve static Spring placeholders

**Files:**
- Create: `nvim/lua/custom/spring_property_navigation.lua`
- Modify: `nvim/lua/key-map.lua:306-318`
- Create: `nvim/tests/spring_property_navigation_spec.lua`

**Step 1: Write failing resolver tests**

Cover extracting `${key}` and `${key:default}`, flattening nested YAML keys, parsing `.properties`, and locating a property in a temporary `src/main/resources` tree.

**Step 2: Run the resolver test to verify it fails**

Run: `nvim --headless -u NONE -l nvim/tests/spring_property_navigation_spec.lua`

Expected: FAIL because the resolver module does not exist.

**Step 3: Implement the minimal static resolver**

Search the current buffer first, then Spring resource files under the project root. Return `false` when no target exists so `gd` continues to MyBatis, i18n, and LSP navigation.

**Step 4: Integrate the resolver before the LSP picker**

Invoke `spring_property_navigation.definition()` after i18n checks and before `Snacks.picker.lsp_definitions()`.

**Step 5: Run the resolver and configuration tests**

Run: `nvim --headless -u NONE -l nvim/tests/spring_property_navigation_spec.lua && nvim --headless -u NONE -l nvim/tests/config_correctness_spec.lua`

Expected: both tests print their success messages.

### Task 3: Verify the actual Spring configuration buffer

**Files:**
- Verify: `moss-service-common-server/src/main/resources/bootstrap.yml`

**Step 1: Start Neovim with the target YAML file**

Inspect `vim.lsp.get_clients({ bufnr = 0 })` after startup.

Expected: both `yamlls` and `spring-boot` are attached.

**Step 2: Invoke the placeholder resolver at `${spring.application.name}`**

Expected: it targets the `spring.application.name` key in the same file.
