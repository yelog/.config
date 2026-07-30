# Maven Dependency Deep Search Expansion Design

## Goal

Expand every visible level of a filtered Maven dependency path, including
multi-level paths such as module, framework, and the matching artifact.

## Root Cause

NUI Tree normalizes a node's public `id` into its internal `_id` by prefixing
it. The previous recursive expansion used `node.id` with `Tree:get_nodes()`,
which only finds children for the root traversal and stops at the next level.

## Design

Use `node._id` when querying NUI Tree children during recursive expansion.
This stays inside the tree's normalized ID namespace and expands each visible
ancestor until the matching dependency becomes visible. No behavior outside an
accepted non-empty tree search changes.

## Testing

Replace the one-level test fixture with `root -> framework-core -> fastjson`.
After searching `fastjson`, assert the renderer contains the matching artifact,
proving every ancestor was expanded.
