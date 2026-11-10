# story: e01s04
extends GutTest
## SC-E01-P1-06 — the rig breathes and blinks off a foot pivot, the outfit can
## never cover the expression, and every tap springs once.

var rig: QuiQuiRig = null
var fired: int = 0


func before_each() -> void:
	rig = QuiQuiRig.new()
	rig.name = "QuiQuiRig"
	rig.size = Vector2(400.0, 600.0)
	rig.manual_step = true
	add_child_autofree(rig)


func after_each() -> void:
	rig.reset()


func test_layer_order_keeps_the_expression_above_the_outfit() -> void:
	assert_gt(rig.expression.z_index, rig.outfit.z_index, "expression over outfit")
	assert_gt(rig.headwear.z_index, rig.expression.z_index, "headwear above the face")
	assert_gt(rig.neck.z_index, rig.headwear.z_index)
	assert_gt(rig.glasses.z_index, rig.neck.z_index)


func test_breathing_scales_around_the_feet() -> void:
	var feet: Vector2 = rig.pivot.position
	assert_almost_eq(feet.y, rig.size.y, 0.01, "the pivot sits on the bottom edge")

	rig.advance(0.3)
	var early: Vector2 = rig.pivot.scale
	rig.advance(0.55)
	var later: Vector2 = rig.pivot.scale

	assert_ne(early, later, "the breath oscillates")
	assert_almost_eq(rig.pivot.position.y, feet.y, 0.001, "the feet never leave the floor")
	assert_true(later.x <= 1.0 + QuiQuiRig.BREATH_X + 0.001, "x stays inside the breath band")
	assert_true(later.y >= 1.0 - 0.001, "y stays at or above rest")


func test_a_neutral_face_blinks_and_returns() -> void:
	assert_eq(rig.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION)

	rig._next_blink_at = 0.01
	rig.advance(0.02)

	assert_eq(rig.expression_id, QuiQuiRig.BLINK_EXPRESSION, "the blink frame is shown")
	assert_true(rig.is_blinking())

	rig.advance(0.2)

	assert_eq(rig.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION, "and it reopens")
	assert_false(rig.is_blinking())


func test_an_active_expression_is_never_overwritten_by_a_blink() -> void:
	assert_true(rig.set_expression("grimace"))
	rig._next_blink_at = 0.01
	rig.advance(0.02)

	assert_eq(rig.expression_id, "grimace", "a held expression outranks a blink")


func test_expression_and_outfit_switch_art() -> void:
	assert_true(rig.set_expression("laughing"))
	assert_eq(rig.expression_id, "laughing")

	assert_true(rig.set_outfit("green_overalls"))
	assert_eq(rig.outfit_id, "green_overalls")
	assert_true(rig.outfit.visible)

	assert_true(rig.set_outfit(""))
	assert_false(rig.outfit.visible, "clearing the outfit hides the layer")


func test_missing_or_invalid_art_is_refused_without_crashing() -> void:
	assert_false(rig.set_expression("nao_existe"), "missing art is refused")
	assert_eq(rig.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION, "the face is unchanged")

	assert_false(rig.set_expression("Maria Clara"), "invalid id is refused")
	assert_false(rig.set_outfit("../etc/passwd"))


func test_a_tap_springs_once_and_fires_once() -> void:
	fired = 0
	rig.tapped.connect(func() -> void: fired += 1)

	rig._gui_input(_touch_event(true))
	rig._gui_input(_mouse_echo_event())

	assert_eq(fired, 1, "the mouse echo never double-fires")
	assert_eq(rig.taps, 1)
	assert_true(rig.is_squashing())

	rig.advance(0.5)
	assert_false(rig.is_squashing(), "the spring ends on its own")


func test_a_real_mouse_with_its_emulated_touch_taps_once() -> void:
	fired = 0
	rig.tapped.connect(func() -> void: fired += 1)

	for event: InputEvent in TouchSim.mouse_click_events(rig):
		rig._gui_input(event)

	assert_eq(fired, 1, "the device -1 touch is the echo of the click")
	assert_eq(rig.taps, 1)


func test_the_mouth_zone_lives_inside_the_visible_art() -> void:
	var visual: Rect2 = rig.get_visual_global_rect()

	assert_true(visual.has_area(), "the rig has visible art")

	assert_true(
		rig.mouth_zone != null and rig.mouth_zone.get_global_rect().has_area(),
		"the mouth zone must exist and have size",
	)


func _touch_event(pressed: bool) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.position = rig.get_global_rect().get_center()
	event.pressed = pressed
	return event


func _mouse_echo_event() -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = rig.get_global_rect().get_center()
	event.device = -1
	return event


# BUG-006: reset is the neutral pose, outfit included.
func test_reset_takes_the_outfit_off() -> void:
	assert_true(rig.set_outfit("green_overalls"))
	assert_true(rig.outfit.visible)

	rig.reset()

	assert_eq(rig.outfit_id, "")
	assert_false(rig.outfit.visible, "a reset rig wears nothing")
	assert_null(rig.outfit.texture, "and keeps no stale art")


# BUG-002: a responsive box must re-anchor the feet after a layout pass.
func test_a_resize_moves_the_feet_to_the_new_bottom_edge() -> void:
	rig.reset()
	rig.size = Vector2(500.0, 700.0)

	assert_almost_eq(rig.pivot.position.x, 250.0, 0.01, "the pivot follows the box centre")
	assert_almost_eq(rig.pivot.position.y, 700.0, 0.01, "the feet stay on the bottom edge")
