# story: e12s04
extends TouchDraggableTestCase
## SC-e12s04-P0-04 — no double fire under mouse echo.


func test_drag_fires_once_with_mouse_echo() -> void:
	_deliver(food, TouchSim.drag_events(food, ON_TARGET, 8, true))
	assert_eq(consumed, 1)
	assert_eq(started, 1)
	assert_true(probe.is_clean(), probe.summary())
