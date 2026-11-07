"""Directional Kitty resizing for IGit. Install in Kitty's config directory."""

try:
    from kittens.tui.handler import result_handler
except ModuleNotFoundError:
    # Allow the pure routing tests to run with the system Python.
    def result_handler(**_kwargs):
        return lambda function: function


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    if len(args) != 3 or args[1] not in {"left", "right", "up", "down"}:
        return
    try:
        amount = int(args[2])
    except (TypeError, ValueError):
        return
    if amount <= 0:
        return
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return
    tab = window.tabref()
    if tab is None or tab.current_layout.name == "stack":
        return
    horizontal = args[1] in {"left", "right"}
    positive = args[1] in {"right", "down"}
    neighbors = tab.current_layout.neighbors_for_window(window, tab.windows)
    before = neighbors.get("left" if horizontal else "top")
    after = neighbors.get("right" if horizontal else "bottom")
    if not before and not after:
        return
    # Prefer the right/bottom boundary, otherwise move the left/top boundary.
    # Resizing by explicit ID also handles a focus change while the request runs.
    increment = amount if positive == bool(after) else -amount
    tab.resize_window_by(window.id, increment, horizontal)
