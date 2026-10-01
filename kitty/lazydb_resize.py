try:
    from kittens.tui.handler import result_handler
except ModuleNotFoundError:
    def result_handler(**_kwargs):
        def decorate(function):
            return function
        return decorate


def _resize_direction(direction, amount, window, boss):
    tab = window.tab
    if tab is None or tab.current_layout.name == "stack":
        return
    neighbors = tab.current_layout.neighbors_for_window(window, tab.windows)
    horizontal = direction in ("left", "right")
    positive = direction in ("right", "down")
    before = neighbors.get("left" if horizontal else "top")
    after = neighbors.get("right" if horizontal else "bottom")
    if not before and not after:
        return
    wider = "wider" if horizontal else "taller"
    narrower = "narrower" if horizontal else "shorter"
    if positive:
        operation = wider if after else narrower
        if not after and before:
            operation = narrower
    else:
        operation = narrower if after else wider
        if not after and before:
            operation = wider
    tab.resize_window(operation, amount)


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
    _resize_direction(args[1], amount, window, boss)
