# story: e01s04
extends GutTest
## The only tap surface (ADR-004): one fire per finger tap, never twice from the
## `device == -1` echo, and a spring that never moves the hit box.

var button: TapButton = null
var taps: int = 0


func before_each() -> void:
	button = TapButton.new()
	button.name = "PlayButton"
	button.size = Vector2(148.0, 148.0)
	add_child_autofree(button)
	taps = 0
	button.tapped.connect(func() -> void: taps += 1)


func _deliver(events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		button._gui_input(event)


func test_touch_with_mouse_echo_fires_exactly_once() -> void:
	_deliver(TouchSim.tap_events(button, true))

	assert_eq(taps, 1, "one finger tap, one fire")
	assert_eq(button.taps, 1)


func test_twenty_taps_fire_twenty_times() -> void:
	for press: int in range(20):
		_deliver(TouchSim.tap_events(button, true))

	assert_eq(taps, 20, "no accumulation, no swallowing")


func test_a_real_mouse_click_is_a_legitimate_tap() -> void:
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.device = 0
	button._gui_input(mouse)

	assert_eq(taps, 1, "device 0 is a real mouse, not an echo")


func test_disabled_button_ignores_input() -> void:
	button.enabled = false
	_deliver(TouchSim.tap_events(button, true))

	assert_eq(taps, 0)


func test_the_hit_box_is_never_smaller_than_120() -> void:
	var fresh: TapButton = TapButton.new()
	fresh.size = Vector2(40.0, 40.0)
	add_child_autofree(fresh)

	assert_true(fresh.size.x >= TapButton.MIN_HIT_SIZE.x, "width grew to the minimum")
	assert_true(fresh.size.y >= TapButton.MIN_HIT_SIZE.y, "height grew to the minimum")


func test_squash_runs_its_three_steps_and_returns_to_rest() -> void:
	button.press()

	assert_true(button.is_squashing())
	assert_eq(button.visual.scale, TapButton.SQUASH_STEPS[0], "first spring keyframe")

	button.advance(0.08)
	assert_eq(button.visual.scale, TapButton.SQUASH_STEPS[1], "second keyframe")

	button.advance(0.10)
	assert_eq(button.visual.scale, TapButton.SQUASH_STEPS[2], "third keyframe")

	button.advance(0.12)
	assert_false(button.is_squashing(), "the spring ends")
	assert_eq(button.visual.scale, Vector2.ONE)


func test_squash_never_changes_the_hit_box() -> void:
	button.press()
	button.advance(0.01)

	assert_eq(button.size, Vector2(148.0, 148.0), "the layout rect is untouched")
	assert_eq(button.visual.scale, TapButton.SQUASH_STEPS[0], "only the art pops")


func test_reset_restores_counters_and_rest_pose() -> void:
	button.press()
	button.advance(0.08)
	button.reset()

	assert_eq(button.taps, 0)
	assert_false(button.is_squashing())
	assert_eq(button.visual.scale, Vector2.ONE)
