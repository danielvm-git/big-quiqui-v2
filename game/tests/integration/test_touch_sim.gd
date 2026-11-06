# story: e01s01
extends GutTest
## SC-E01-P0-07 — the tap contract: a touch plus the `device == -1` mouse echo.
##
## Godot's headless viewport does not dispatch GUI input through
## `Viewport.push_input` (probed: a plain mouse press with device 0 also reaches
## no `_gui_input`), so this test proves the contract where it is decidable:
## on the event sequence AND on the handlers that consume it. Window-level
## dispatch is covered by the on-device UAT of the first playable scene (e01s05).


class FilteredTap:
	extends Control
	var taps: int = 0

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouse and (event as InputEventMouse).device == -1:
			return
		if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
			taps += 1


class NaiveTap:
	extends Control
	var taps: int = 0

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
			taps += 1
		elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			taps += 1


func _spawn(control: Control, at: Vector2) -> Control:
	control.size = Vector2(200.0, 200.0)
	control.position = at
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child_autofree(control)
	return control


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(event)


func test_tap_events_are_touch_press_echo_press_echo_release_touch_release() -> void:
	var control: Control = _spawn(Control.new(), Vector2(60.0, 60.0))
	var events: Array[InputEvent] = TouchSim.tap_events(control, true)

	assert_eq(events.size(), 4, "press + mouse press + mouse release + release")
	assert_true(events[0] is InputEventScreenTouch)
	assert_true((events[0] as InputEventScreenTouch).pressed)

	assert_true(events[1] is InputEventMouseButton)
	assert_eq((events[1] as InputEventMouseButton).device, -1, "the echo carries device -1")
	assert_true((events[1] as InputEventMouseButton).pressed)

	assert_true(events[2] is InputEventMouseButton)
	assert_false((events[2] as InputEventMouseButton).pressed)

	assert_true(events[3] is InputEventScreenTouch)
	assert_false((events[3] as InputEventScreenTouch).pressed)


func test_touches_are_real_device_zero_events() -> void:
	var control: Control = _spawn(Control.new(), Vector2(60.0, 60.0))
	var events: Array[InputEvent] = TouchSim.drag_events(control, Vector2(400.0, 400.0), 2, false)
	events.append_array(TouchSim.tap_events(control, false))

	for event: InputEvent in events:
		assert_eq(event.device, 0, "a finger is a real device, not an echo")


func test_a_mouse_click_pairs_each_real_button_event_with_an_emulated_touch() -> void:
	var control: Control = _spawn(Control.new(), Vector2(60.0, 60.0))
	var events: Array[InputEvent] = TouchSim.mouse_click_events(control)

	assert_eq(events.size(), 4)
	for pair: int in range(2):
		assert_true(events[pair * 2] is InputEventScreenTouch)
		assert_eq(events[pair * 2].device, -1, "the touch is the emulated one")
		assert_true(events[pair * 2 + 1] is InputEventMouseButton)
		assert_eq(events[pair * 2 + 1].device, 0, "the mouse is the real one")


func test_a_mouse_drag_presses_moves_and_releases_as_emulated_pairs() -> void:
	var control: Control = _spawn(Control.new(), Vector2(60.0, 60.0))
	var events: Array[InputEvent] = TouchSim.mouse_drag_events(control, Vector2(400.0, 400.0), 2)

	assert_eq(events.size(), 8, "press pair + 2 motion pairs + release pair")
	assert_true(events[2] is InputEventScreenDrag)
	assert_eq(events[2].device, -1)
	assert_true(events[3] is InputEventMouseMotion)
	assert_eq(events[3].device, 0)


func test_no_echo_means_only_the_touch_pair() -> void:
	var control: Control = _spawn(Control.new(), Vector2(320.0, 60.0))
	var events: Array[InputEvent] = TouchSim.tap_events(control, false)

	assert_eq(events.size(), 2, "press + release, nothing else")
	for event: InputEvent in events:
		assert_true(event is InputEventScreenTouch)


func test_filtered_handler_fires_once() -> void:
	var filtered: FilteredTap = _spawn(FilteredTap.new(), Vector2(580.0, 60.0)) as FilteredTap

	_deliver(filtered, TouchSim.tap_events(filtered, true))

	assert_eq(filtered.taps, 1, "a device==-1 filter yields exactly one tap")


func test_unfiltered_handler_double_fires_proving_the_echo_is_honest() -> void:
	var naive: NaiveTap = _spawn(NaiveTap.new(), Vector2(840.0, 60.0)) as NaiveTap

	_deliver(naive, TouchSim.tap_events(naive, true))

	assert_eq(
		naive.taps,
		2,
		"touch + synthesized mouse = two presses; this is the regression the filter prevents",
	)


func test_drag_sequence_presses_once_and_releases_once() -> void:
	var control: Control = _spawn(Control.new(), Vector2(1100.0, 60.0))
	var events: Array[InputEvent] = TouchSim.drag_events(control, Vector2(1200.0, 300.0), 4, true)

	# press + echo + 4 drag steps + 4 mouse motions + touch release + mouse release
	assert_eq(events.size(), 12)
	assert_true(events[0] is InputEventScreenTouch)
	assert_true((events[0] as InputEventScreenTouch).pressed)
	assert_eq((events[1] as InputEventMouseButton).device, -1)
	assert_true(events[2] is InputEventScreenDrag)
	assert_true(events[-1] is InputEventMouseButton)
	assert_false((events[-1] as InputEventMouseButton).pressed)
