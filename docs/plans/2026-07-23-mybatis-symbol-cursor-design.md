# MyBatis Symbol Cursor Design

## Goal

Make MyBatis navigation place the cursor on the resolved Java Mapper method name
or XML statement `id` value instead of at the start of its line.

## Scope

Apply the behavior to every MyBatis target selected by `gd` and `gD`, including
Java-to-XML, XML-to-Java, and call-site-to-XML navigation. File-level fallback
targets keep their current line-start location.

## Design

Navigation targets will carry an optional zero-based `col` field in addition to
their path and one-based row. XML statement matching will calculate the start
of the `id` attribute value, and Java method matching will calculate the start
of the method name. The shared target opener will use `col` when present and
otherwise default to zero.

## Validation

Extend the focused Lua tests to assert Java method columns, XML `id` columns
for both quote styles, and the default-column fallback. Run the existing
MyBatis navigation test through headless Neovim.
