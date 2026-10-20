# Java properties Unicode search implementation plan

**Goal:** Read escaped Java properties as Chinese and support both `/` and Cmd+Shift+F without migrating project files.

**Architecture:** Share one Unicode codec between Neovim's native `charconvert` file I/O and a ripgrep preprocessor. Apply preprocessing only to `.properties`; preserve line numbers and decoded UTF-8 byte columns in results, previews, and opened buffers. Retain unchanged raw lines and escape spellings when writing.

**Tech stack:** Neovim Lua, native file encoding conversion, Snacks Picker, ripgrep `--pre` / `--pre-glob`.

## Task 1: Codec and native file conversion

- Create `nvim/lua/custom/java_properties.lua` and `nvim/lua/custom/properties_codec.lua`.
- Initialize the conversion hooks before plugin loading in `nvim/init.lua`.
- Add `nvim/tests/java_properties_spec.lua` covering actual Chinese search, no-op writes, edited writes, undo, invalid escapes, literal backslashes, surrogate pairs, UTF-8 files, CRLF, and missing final newline.
- Use native `charconvert` with a private encoding name, restoring `fileencodings` after each read. Delegate unrelated conversions to the previous converter.
- Prevent Gitsigns from attaching to transformed buffers because its index/staging operations expect the raw file representation.
- Run `nvim --clean --headless -l nvim/tests/java_properties_spec.lua` and require all assertions to pass.

## Task 2: Project search and preview

- Create executable `nvim/scripts/properties-search` using the shared codec.
- Extend `nvim/lua/custom/project_search.lua` with `--pre` and `--pre-glob=*.properties` and decoded previews.
- Add `nvim/tests/properties_search_spec.lua` exercising actual ripgrep matches in escaped and UTF-8 files, regex, case/word flags, masks, mixed text, byte columns, and unchanged source bytes.
- Keep the existing project search option behavior and run its regression tests.

## Task 3: Integration and documentation

- Document Chinese search and unchanged on-disk escaping in `nvim/README.md`, including disk-based search and the Gitsigns limitation.
- Verify the real user file read-only with the complete Neovim configuration, then test picker result resolution, preview, and jump with a temporary fixture.
- Check the final diff and source hashes. Do not commit or modify the Java project.

## Completed validation

- `nvim --clean --headless -l nvim/tests/java_properties_spec.lua`: passed, including native slash search,
  exact round trips, edits, undo, range writes, failed writes, raw inspection, CRLF, and missing final newline.
- `nvim --clean --headless -l nvim/tests/properties_search_spec.lua`: passed against real ripgrep.
- `nvim --clean --headless -l nvim/tests/project_search_spec.lua`: passed.
- `nvim --clean --headless -l nvim/tests/config_correctness_spec.lua`: passed.
- `nvim --headless -i NONE -n '+lua dofile("nvim/tests/properties_picker_spec.lua")'`: passed with the complete
  configuration; verified decoded results, preview, repeated preview, highlights, confirmation, and cursor columns.
- Opened the user's source file read-only with the complete configuration: Chinese slash search matches line 1.
- Round-tripped a temporary copy of the user's complete file through no-op save, Chinese/emoji edits, undo, and save:
  all original bytes recovered and all other lines preserved during the edit.
- One local search measurement over 19 properties files: raw 15 ms, decoded 37 ms. No project files changed.
- `git diff --check`: passed.
