# story: e03s02
extends GutTest
## QuiQuiRig anticipation edge cases, mouth-zone enclosure, and opaque visual bounds.

var rig: QuiQuiRig = null


func before_each() -> void:
	rig = QuiQuiRig.new()
	rig.name = "QuiQuiRig"
	rig.size = Vector2(400.0, 600.0)
	rig.manual_step = true
	add_child_autofree(rig)


func after_each() -> void:
	rig.reset()


func test_a_face_set_during_anticipation_is_not_overwritten_by_the_restore() -> void:
	rig.update_food_proximity(_point_at(10.0))
	assert_true(rig.set_expression("chewing"))

	rig.clear_food_proximity()

	assert_eq(rig.expression_id, "chewing", "the eating face outranks the old one")


# SC-E03-P1-12: the blink does not fight anticipation.
func test_the_blink_never_overwrites_the_open_mouth() -> void:
	rig.update_food_proximity(_point_at(10.0))

	rig.advance(QuiQuiRig.BLINK_MAX_SEC)
	assert_eq(rig.expression_id, QuiQuiRig.ANTICIPATION_EXPRESSION, "a blink came due")
	rig.advance(QuiQuiRig.BLINK_HOLD_SEC * 2.0)
	assert_eq(rig.expression_id, QuiQuiRig.ANTICIPATION_EXPRESSION, "and it stayed away")


func test_food_arriving_mid_blink_restores_the_open_eyes() -> void:
	rig.advance(QuiQuiRig.BLINK_MAX_SEC)
	assert_eq(rig.expression_id, QuiQuiRig.BLINK_EXPRESSION, "the blink frame is shown")

	rig.update_food_proximity(_point_at(10.0))
	assert_eq(rig.expression_id, QuiQuiRig.ANTICIPATION_EXPRESSION, "food wins over the blink")
	rig.advance(0.5)
	assert_eq(rig.expression_id, QuiQuiRig.ANTICIPATION_EXPRESSION, "the blink end changes nothing")

	rig.clear_food_proximity()
	assert_eq(rig.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION, "never stuck on the blink frame")


func test_reset_clears_anticipation() -> void:
	assert_true(rig.set_expression("needy"))
	rig.update_food_proximity(_point_at(10.0))

	rig.reset()
	assert_eq(rig.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION)

	rig.update_food_proximity(_point_at(10.0))
	assert_eq(rig.expression_id, QuiQuiRig.ANTICIPATION_EXPRESSION, "the next approach still works")

	rig.clear_food_proximity()
	assert_eq(rig.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION, "the old face is forgotten")


# SC-E03-P1-13: the mouth zone lies inside the art, on a real layout.
func test_the_mouth_zone_is_enclosed_by_the_visual_rect_on_real_layouts() -> void:
	for box: Vector2 in [Vector2(400.0, 600.0), Vector2(640.0, 620.0), Vector2(600.0, 900.0)]:
		rig.size = box
		_assert_mouth_zone_enclosed("box %s" % box)

	rig.position = Vector2(640.0, 222.0)
	_assert_mouth_zone_enclosed("moved on screen")

	rig.advance(0.7)
	_assert_mouth_zone_enclosed("mid breath")

	rig.scale = Vector2(1.5, 1.5)
	_assert_mouth_zone_enclosed("scaled")


func _assert_mouth_zone_enclosed(label: String) -> void:
	var visual: Rect2 = rig.get_visual_global_rect()
	var zone: Rect2 = rig.mouth_zone.get_global_rect()

	assert_true(zone.has_area(), "%s: the zone has size" % label)
	assert_true(visual.encloses(zone), "%s: %s inside %s" % [label, zone, visual])


func _point_at(distance: float) -> Vector2:
	return rig.mouth_global_center() + Vector2(distance, 0.0)


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
	mounted.anchor_left = 0.5
	mounted.anchor_right = 0.5
	mounted.anchor_top = 0.78 - 620.0 / 1080.0
	mounted.anchor_bottom = 0.78
	mounted.offset_left = -320.0
	mounted.offset_right = 320.0
	stage.add_child(mounted)
	await wait_process_frames(2)

	var painted: Rect2 = mounted.get_visual_global_rect()

	assert_almost_eq(mounted.size.y, 620.0 / 1080.0 * 1440.0, 1.0, "the height still comes from the ratio")
	assert_almost_eq(painted.size.y, mounted.size.y, mounted.size.y * 0.03, "the art fills the box height")
	assert_almost_eq(mounted.size.x, painted.size.x, mounted.size.x * 0.03, "and the box widens with the art")
	assert_almost_eq(painted.get_center().x, mounted.global_position.x + mounted.size.x * 0.5, 1.0)
	assert_almost_eq(painted.end.y, mounted.global_position.y + mounted.size.y, 1.0)
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
	for expression_id: String in ["base", "wink", "laughing", "needy", "sleepy", "jumping"]:
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
	await wait_process_frames(2)

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
	await wait_process_frames(2)

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


# BUG-015: right-click must not count as a tap, and mouth_global_center() must not crash before _ready().
func test_right_mouse_button_is_ignored_and_mouth_center_is_safe_before_ready() -> void:
	var cold: QuiQuiRig = QuiQuiRig.new()
	assert_eq(cold.mouth_global_center(), Vector2.ZERO, "safe before _ready")
	cold.free()

	var right_click: InputEventMouseButton = InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	right_click.position = rig.get_visual_global_rect().get_center()
	rig._gui_input(right_click)
	assert_eq(rig.taps, 0, "only left mouse button counts as a tap")
