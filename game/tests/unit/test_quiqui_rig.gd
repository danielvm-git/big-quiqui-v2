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
	assert_true(rig.set_expression("careta"))
	rig._next_blink_at = 0.01
	rig.advance(0.02)

	assert_eq(rig.expression_id, "careta", "a held expression outranks a blink")


func test_expression_and_outfit_switch_art() -> void:
	assert_true(rig.set_expression("rindo"))
	assert_eq(rig.expression_id, "rindo")

	assert_true(rig.set_outfit("macacao_verde"))
	assert_eq(rig.outfit_id, "macacao_verde")
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
	assert_true(rig.set_outfit("macacao_verde"))
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


# Review F1: missing art must not write a diary line on every motion. The subclass
# is the seam, so production code gains no switch.
class RigWithoutOpenMouth:
	extends QuiQuiRig

	func _load_art(id: String) -> Texture2D:
		return null if id == ANTICIPATION_EXPRESSION else super(id)


func _rig_without_open_mouth() -> QuiQuiRig:
	var broken: QuiQuiRig = RigWithoutOpenMouth.new()
	broken.size = Vector2(400.0, 600.0)
	broken.manual_step = true
	add_child_autofree(broken)
	return broken


func test_missing_mouth_art_logs_once_over_thirty_near_motions() -> void:
	var broken: QuiQuiRig = _rig_without_open_mouth()
	var near: Vector2 = broken.mouth_global_center() + Vector2(100.0, 0.0)
	var diary: Node = get_node("/root/Log")
	var before: int = diary.call("write_count")

	for motion: int in range(30):
		broken.update_food_proximity(near)

	assert_eq(diary.call("write_count") - before, 1, "one rig.missing_art, not one per motion")
	assert_eq(broken.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION, "she keeps her face")


func test_missing_mouth_art_is_retried_on_the_next_approach_and_keeps_her_face() -> void:
	var broken: QuiQuiRig = _rig_without_open_mouth()
	var near: Vector2 = broken.mouth_global_center() + Vector2(100.0, 0.0)
	var diary: Node = get_node("/root/Log")
	var before: int = diary.call("write_count")

	broken.update_food_proximity(near)
	broken.clear_food_proximity()
	broken.update_food_proximity(near)

	assert_eq(diary.call("write_count") - before, 2, "one line per approach")
	assert_eq(broken.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION)


# SC-E03-P0-08: the 220 px boundary, both sides.
func test_a_point_under_the_threshold_opens_the_mouth_on_that_call() -> void:
	rig.update_food_proximity(_point_at(219.99))

	assert_eq(rig.expression_id, QuiQuiRig.ANTICIPATION_EXPRESSION)


func test_a_point_exactly_on_the_threshold_does_not_open_the_mouth() -> void:
	rig.update_food_proximity(_point_at(QuiQuiRig.MOUTH_ANTICIPATION_PX))

	assert_eq(rig.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION)


func test_a_point_past_the_threshold_does_not_open_the_mouth() -> void:
	rig.update_food_proximity(_point_at(220.01))

	assert_eq(rig.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION)


func test_the_mouth_centre_follows_the_rig_on_screen() -> void:
	var before: Vector2 = rig.mouth_global_center()
	rig.position += Vector2(300.0, 40.0)

	assert_eq(rig.mouth_global_center(), before + Vector2(300.0, 40.0))
	assert_eq(rig.mouth_global_center(), rig.mouth_zone.get_global_rect().get_center())


# SC-E03-P0-09: restore to the previous face.
func test_moving_away_restores_the_face_shown_before() -> void:
	assert_true(rig.set_expression("carente"))

	rig.update_food_proximity(_point_at(10.0))
	assert_eq(rig.expression_id, QuiQuiRig.ANTICIPATION_EXPRESSION)

	rig.update_food_proximity(_point_at(400.0))
	assert_eq(rig.expression_id, "carente", "not always base")


func test_clearing_restores_the_face_shown_before() -> void:
	assert_true(rig.set_expression("carente"))
	rig.update_food_proximity(_point_at(10.0))

	rig.clear_food_proximity()

	assert_eq(rig.expression_id, "carente")


func test_repeated_calls_while_close_do_not_re_emit() -> void:
	var faces: Array[String] = _record_faces()

	rig.update_food_proximity(_point_at(100.0))
	rig.update_food_proximity(_point_at(90.0))
	rig.update_food_proximity(_point_at(80.0))

	assert_eq(faces, [QuiQuiRig.ANTICIPATION_EXPRESSION] as Array[String])


func test_repeated_calls_while_close_keep_the_face_to_restore() -> void:
	assert_true(rig.set_expression("carente"))

	rig.update_food_proximity(_point_at(100.0))
	rig.update_food_proximity(_point_at(90.0))
	rig.update_food_proximity(_point_at(400.0))

	assert_eq(rig.expression_id, "carente", "the mouth never stays stuck open")


func test_a_second_approach_still_restores_the_original_face() -> void:
	assert_true(rig.set_expression("carente"))

	rig.update_food_proximity(_point_at(10.0))
	rig.update_food_proximity(_point_at(400.0))
	rig.update_food_proximity(_point_at(10.0))
	rig.clear_food_proximity()

	assert_eq(rig.expression_id, "carente")


func test_clearing_without_anticipation_changes_nothing() -> void:
	assert_true(rig.set_expression("carente"))
	var faces: Array[String] = _record_faces()
	rig.clear_food_proximity()
	rig.update_food_proximity(_point_at(400.0))
	assert_eq(rig.expression_id, "carente")
	assert_eq(faces.size(), 0, "no signal without a change")


func _point_at(distance: float) -> Vector2:
	return rig.mouth_global_center() + Vector2(distance, 0.0)


func _record_faces() -> Array[String]:
	var faces: Array[String] = []
	rig.expression_changed.connect(func(id: String) -> void: faces.append(id))
	return faces


# e04s01 / T-E04-01: the scrub hull is authored in rig-local space while the box
# follows the opaque art per aspect, so it has to be rebuilt on every layout pass.
# A hull cached at one canvas size passes every 16:9 check and fails only on iPad.
func test_the_hull_follows_the_opaque_rect_on_every_canvas() -> void:
	for canvas: Vector2i in [Vector2i(1920, 1080), Vector2i(1920, 1440), Vector2i(2048, 1536)]:
		var viewport: SubViewport = SubViewport.new()
		viewport.size = canvas
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child_autofree(viewport)
		var stage: Control = Control.new()
		stage.set_anchors_preset(Control.PRESET_FULL_RECT)
		viewport.add_child(stage)

		var mounted: QuiQuiRig = QuiQuiRig.new()
		mounted.manual_step = true
		mounted.anchor_left = 0.5
		mounted.anchor_right = 0.5
		mounted.anchor_top = 0.78 - 620.0 / 1080.0
		mounted.anchor_bottom = 0.78
		mounted.offset_left = -320.0
		mounted.offset_right = 320.0
		stage.add_child(mounted)
		await wait_frames(2)

		var hull: PackedVector2Array = mounted.scrub_hull_global()
		var painted: Rect2 = mounted.get_visual_global_rect()
		assert_eq(hull.size(), QuiQuiRig.SCRUB_HULL_POINTS, "%s: hull vertex count" % canvas)

		var box: Rect2 = Rect2(hull[0], Vector2.ZERO)
		for point: Vector2 in hull:
			box = box.expand(point)

		assert_true(painted.grow(1.0).encloses(box), "%s: hull %s must live inside the art %s" % [canvas, box, painted])
		assert_almost_eq(
			box.size.y,
			painted.size.y - QuiQuiRig.SCRUB_HULL_INSET * 2.0,
			4.0,
			"%s: hull follows the art height" % canvas
		)
		assert_almost_eq(box.get_center().x, float(canvas.x) * 0.5, 3.0, "%s: and stays centred" % canvas)
		assert_gt(box.size.y / float(canvas.y), 0.5, "%s: the hull is the body, not a button" % canvas)

		viewport.queue_free()
		await wait_frames(1)


func test_the_hull_contains_the_body_and_not_the_transparent_margin() -> void:
	var painted: Rect2 = rig.get_visual_global_rect()
	var hull: PackedVector2Array = rig.scrub_hull_global()

	assert_gt(hull.size(), 2, "a polygon, not a point list")
	var box: Rect2 = Rect2(hull[0], Vector2.ZERO)
	for point: Vector2 in hull:
		box = box.expand(point)
	assert_lt(box.size.y, painted.size.y, "the hull is inset inside the opaque art")
	assert_gt(box.size.y, painted.size.y * 0.8, "but not so far in that the body is unreachable")


# e05s01 / T-E05-03: the face is the only feedback a pre-reader has, so the outfit
# and every accessory that could hide it must stay behind the expression layer.
func test_the_expression_layer_sits_above_outfit_and_accessories() -> void:
	assert_true(rig.set_outfit("vestido_florido"), "the outfit loads")
	assert_true(rig.set_accessory("head", "tiara_flores"))
	assert_true(rig.set_accessory("eyes", "oculos_coracao"))
	rig.set_expression("base")

	assert_gt(rig.expression.z_index, rig.outfit.z_index, "the face is above the dress")
	assert_true(rig.expression.visible, "and visible")
	# A hat and glasses may sit above the face, but their art must not reach the mouth.
	var mouth: Vector2 = rig.mouth_global_center()
	for slot: String in ["head", "eyes"]:
		var sprite: Sprite2D = rig.headwear if slot == "head" else rig.glasses
		assert_false(
			_art_rect(sprite).has_point(mouth),
			"%s art must not cover the mouth zone at %s" % [slot, mouth],
		)


func _art_rect(sprite: Sprite2D) -> Rect2:
	return Rect2(
		sprite.global_position - sprite.texture.get_size() * 0.5 * sprite.global_scale,
		sprite.texture.get_size() * sprite.global_scale
	)


# T-E05-05: one accessory per slot. A second hat replaces the first, it does not stack.
func test_a_second_accessory_replaces_the_first_in_its_slot() -> void:
	assert_true(rig.set_accessory("head", "tiara_flores"))
	assert_true(rig.set_accessory("head", "coroa"))
	assert_eq(rig.accessory_id("head"), "coroa", "the newest hat wins")
	assert_eq(rig.accessory_id("eyes"), "", "and other slots are untouched")


func test_an_invalid_accessory_is_refused_and_changes_nothing() -> void:
	for bad: String in ["../etc/passwd", "TIARA", "a".repeat(65), "id.with.dot"]:
		assert_false(rig.set_accessory("head", bad), bad)
	assert_eq(rig.accessory_id("head"), "", "nothing was equipped")


func test_an_unknown_slot_is_refused_loudly_enough_to_debug() -> void:
	assert_false(rig.set_accessory("tail", "tiara_flores"))
	assert_true(rig.get_visual_global_rect().has_area(), "and the rig still renders")
