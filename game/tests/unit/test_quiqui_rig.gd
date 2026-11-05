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


# BUG-013: the box height is a ratio, so the box has to be art-shaped or the
# width-limited fit shrinks the character as the canvas gets taller.
func test_the_box_widens_with_the_height_on_a_centre_anchored_rig() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1920, 1440)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var stage: Control = Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(stage)

	var mounted: QuiQuiRig = QuiQuiRig.new()
	mounted.manual_step = true
	# The builder's contract: a centred column, height from the feet line ratio.
	mounted.anchor_left = 0.5
	mounted.anchor_right = 0.5
	mounted.anchor_top = 0.78 - 620.0 / 1080.0
	mounted.anchor_bottom = 0.78
	mounted.offset_left = -320.0
	mounted.offset_right = 320.0
	stage.add_child(mounted)
	await wait_frames(2)

	var painted: Rect2 = mounted.get_visual_global_rect()

	assert_almost_eq(mounted.size.y, 620.0 / 1080.0 * 1440.0, 1.0, "the height still comes from the ratio")
	assert_almost_eq(painted.size.y, mounted.size.y, mounted.size.y * 0.03, "the art fills the box height")
	assert_almost_eq(mounted.size.x, painted.size.x, mounted.size.x * 0.03, "and the box widens with the art")
	assert_gt(painted.size.y / 1440.0, 0.55, "the painted character keeps DESIGN §3 on a 4:3 canvas")


# BUG-013 / round-2 must-fix: the design unit is the opaque character, not the
# 1024x1024 frame that carries an ~8 % transparent margin.
func test_the_character_is_measured_on_its_opaque_pixels() -> void:
	var sprite: Sprite2D = rig.expression
	var frame_height: float = sprite.texture.get_size().y * sprite.global_scale.y
	var painted: Rect2 = rig.get_visual_global_rect()
	var box: Rect2 = rig.get_global_rect()

	assert_true(painted.has_area(), "QuiQui is visible")
	assert_lt(painted.size.y, frame_height * 0.95, "the art frame carries transparent margin")
	assert_almost_eq(painted.end.y, box.end.y, 2.0, "the visible feet sit on the pivot line")
	assert_almost_eq(painted.get_center().x, box.get_center().x, 2.0, "the visible centre is the box centre")


# Every shipped base pose must stay in the design band: fitting each pose on its
# own opaque rect keeps the seen height constant even though `carente` and `sono`
# are shorter in frame pixels than `base`.
func test_every_base_pose_keeps_the_height_and_the_feet() -> void:
	for expression_id: String in ["base", "pisca", "rindo", "carente", "sono", "pulando"]:
		if not rig.set_expression(expression_id):
			continue
		var painted: Rect2 = rig.get_visual_global_rect()
		var box: Rect2 = rig.get_global_rect()
		assert_almost_eq(painted.size.y, box.size.y, box.size.y * 0.02, "%s keeps the box height" % expression_id)
		assert_almost_eq(painted.end.y, box.end.y, 2.0, "%s keeps the feet on the line" % expression_id)


# Round 3: an unreadable image must not silently become "the frame is the character".
func test_unreadable_art_reports_no_painted_geometry() -> void:
	var placeholder: PlaceholderTexture2D = PlaceholderTexture2D.new()
	placeholder.size = Vector2(1024.0, 1024.0)

	assert_false(rig.opaque_rect(placeholder).has_area(), "cannot measure is empty, not the frame")
	assert_true(rig.get_visual_global_rect().has_area(), "and the shipped art still measures")


# Round 5: the suite must be able to tell `get_visual_global_rect()` from the
# `Control` box, or the gate could be "fixed" back to measuring the box by
# replacing the getter with `get_global_rect()` and nothing would notice.
# A stretched column disables the width fit, so the two rects must diverge.
func test_the_painted_rect_is_not_the_control_box() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(2048, 1536)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var stage: Control = Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(stage)

	var stretched: QuiQuiRig = QuiQuiRig.new()
	stretched.manual_step = true
	stretched.anchor_left = 0.0
	stretched.anchor_right = 1.0
	stretched.anchor_top = 0.78 - 620.0 / 1080.0
	stretched.anchor_bottom = 0.78
	stage.add_child(stretched)
	await wait_frames(2)

	var box: Rect2 = stretched.get_global_rect()
	var painted: Rect2 = stretched.get_visual_global_rect()

	assert_true(painted.has_area(), "the character is visible")
	assert_almost_eq(painted.size.y, box.size.y, box.size.y * 0.03, "the seen height still fills the box")
	assert_lt(painted.size.x, box.size.x * 0.5, "but the seen width is the art, not the column")
	assert_ne(painted, box, "a getter that echoed the box would fail here")


# BUG-013: even when a layout leaves dead space around the character, tapping the
# empty box outside `get_visual_global_rect()` must not trigger affection.
func test_taps_outside_the_painted_character_are_ignored() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(2048, 1536)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var stage: Control = Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(stage)

	var stretched: QuiQuiRig = QuiQuiRig.new()
	stretched.manual_step = true
	stretched.anchor_left = 0.0
	stretched.anchor_right = 1.0
	stretched.anchor_top = 0.78 - 620.0 / 1080.0
	stretched.anchor_bottom = 0.78
	stage.add_child(stretched)
	await wait_frames(2)

	var miss: InputEventScreenTouch = InputEventScreenTouch.new()
	miss.position = Vector2(12.0, 12.0)
	miss.pressed = true
	stretched._gui_input(miss)
	assert_eq(stretched.taps, 0, "blank box outside the character is not tappable")

	var hit: InputEventScreenTouch = InputEventScreenTouch.new()
	hit.position = stretched.get_visual_global_rect().get_center()
	hit.pressed = true
	stretched._gui_input(hit)
	assert_eq(stretched.taps, 1, "tapping the painted character still fires")
