# Maven Dependency Search Interaction Design

## Goal

After a dependency search is accepted, return keyboard focus to the Maven
dependency popup and expose every visible ancestor path to matching artifacts.

## Design

`vim.ui.input` temporarily owns focus while the query is edited. Its completion
callback must explicitly restore `popup.winid`; otherwise the active window can
remain the buffer beneath the popup. On an accepted non-empty query, render the
filtered tree and recursively expand its visible nodes with children. This
exposes the retained path to every match without expanding unrelated nodes.

Cancelling the input leaves both focus and tree state unchanged. Clearing a
query redraws the normal, initially collapsed tree and does not force expansion.

## Testing

Headless analyzer tests will stub `vim.ui.input`, assert the popup window is
focused after completion, and assert filtered parent nodes are expanded while
the normal tree remains unaffected.
