# story: e01s01
extends GutTest
## SC-E01-P1-08 — the layout oracle proves the dual-aspect contract:
## background covers the whole viewport (zero letterbox bars) and every hit
## target is at least 120x120 px and inside the viewport.


func _build_stage(size: Vector2i, hit_size: Vector2) -> Array:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)

	var stage: Control = Control.new()
	stage.name = "Stage"
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(stage)

	var background: TextureRect = TextureRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.add_to_group(GeometryOracle.HIT_GROUP, false)
	background.remove_from_group(GeometryOracle.HIT_GROUP)
	background.add_to_group("background", false)
	stage.add_child(background)

	var button: Button = Button.new()
	button.name = "PlayButton"
	button.size = hit_size
	button.position = Vector2(100.0, 100.0)
	button.add_to_group(GeometryOracle.HIT_GROUP, false)
	stage.add_child(button)

	return [viewport, stage]


func test_both_aspects_pass_with_a_full_background_and_a_big_enough_target() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		var stage: Control = _build_stage(size, Vector2(148.0, 148.0))[1] as Control
		await wait_frames(2)

		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(stage, size)
		assert_true(findings.is_empty(), "%dx%d: %s" % [size.x, size.y, oracle.summary()])


func test_small_hit_target_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.DESKTOP_16_9, Vector2(96.0, 96.0))[1] as Control
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.DESKTOP_16_9)

	assert_false(findings.is_empty(), "a 96x96 target must fail the oracle")
	assert_true(oracle.summary().contains("minimum is"), oracle.summary())


func test_letterboxed_background_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.DESKTOP_16_9, Vector2(148.0, 148.0))[1] as Control
	var background: TextureRect = stage.get_node("Background") as TextureRect
	background.set_anchors_preset(Control.PRESET_CENTER)
	background.size = Vector2(960.0, 540.0)
	background.position = Vector2(480.0, 270.0)
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.DESKTOP_16_9)

	assert_false(findings.is_empty(), "a half-size background must be reported as bars")
	assert_true(oracle.summary().contains("letterbox"), oracle.summary())


# ── ADR-008 regression guards (BUG-001 / BUG-002) ────────────────────────────
#
# The oracle earned these because the first two scenes shipped green with a 2x
# scene root (a `>=` coverage test passes for any oversized node) and with
# 16:9 pixel coordinates on the 4:3 canvas (nothing asserted the ratios).


func test_an_oversized_background_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.DESKTOP_16_9, Vector2(148.0, 148.0))[1] as Control
	await wait_frames(2)
	var background: TextureRect = stage.get_node("Background") as TextureRect
	# Same failure the builders produced: full-rect anchors + a packed size.
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_right = 1920.0
	background.offset_bottom = 1080.0
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.DESKTOP_16_9)

	assert_false(findings.is_empty(), "a 2x background must fail the oracle")
	assert_true(oracle.summary().contains("oversized"), oracle.summary())


func test_a_rig_off_the_feet_line_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.DESKTOP_16_9, Vector2(148.0, 148.0))[1] as Control
	_add_edges(stage, GeometryOracle.DESKTOP_16_9)
	var rig: PaintedBox = _add_painted_control(stage, "Rig", GeometryOracle.RIG_GROUP)
	rig.position = Vector2(640.0, 222.0)
	rig.size = Vector2(640.0, 400.0)
	rig.painted = rig.get_global_rect()
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.DESKTOP_16_9, GeometryOracle.CARE_ROOM_SPEC)

	assert_false(findings.is_empty(), "622 px of feet instead of 842 must fail: %s" % oracle.summary())
	assert_true(oracle.summary().contains("feet at"), oracle.summary())


func test_a_bottom_bar_that_floats_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.DESKTOP_16_9, Vector2(148.0, 148.0))[1] as Control
	var dots: Control = _add_group_control(stage, "Dots", GeometryOracle.BOTTOM_GROUP)
	dots.position = Vector2(732.0, 600.0)
	dots.size = Vector2(456.0, 72.0)
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.DESKTOP_16_9, GeometryOracle.CARE_ROOM_SPEC)

	assert_false(findings.is_empty(), "a bottom strip 400 px up must fail: %s" % oracle.summary())
	assert_true(oracle.summary().contains("bottom edge"), oracle.summary())


func test_a_correctly_anchored_rig_passes_the_care_room_spec() -> void:
	var stage: Control = _build_stage(GeometryOracle.IPAD_4_3, Vector2(148.0, 148.0))[1] as Control
	_add_edges(stage, GeometryOracle.IPAD_4_3)
	var rig: PaintedBox = _add_painted_control(stage, "Rig", GeometryOracle.RIG_GROUP)
	# 620 / 1080 of the height, feet on 78 %, centred: the ADR-008 contract.
	rig.anchor_left = 0.5
	rig.anchor_right = 0.5
	rig.anchor_top = 0.78 - 620.0 / 1080.0
	rig.anchor_bottom = 0.78
	rig.offset_left = -320.0
	rig.offset_right = 320.0
	await wait_frames(2)
	rig.painted = rig.get_global_rect()

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.IPAD_4_3, GeometryOracle.CARE_ROOM_SPEC)

	assert_true(findings.is_empty(), oracle.summary())


## The care-room spec requires the two edge strips; every happy-path stage needs
## them, placed inside the canvas it was built for.
func _add_edges(stage: Control, size: Vector2i) -> void:
	var canvas: Vector2 = Vector2(size)
	var bottom: Control = _add_group_control(stage, "Dots", GeometryOracle.BOTTOM_GROUP)
	bottom.size = Vector2(456.0, 72.0)
	bottom.position = Vector2((canvas.x - 456.0) * 0.5, canvas.y - 36.0 - 72.0)
	var hud: Control = _add_group_control(stage, "Hud", GeometryOracle.TOP_RIGHT_GROUP)
	hud.size = Vector2(244.0, 72.0)
	hud.position = Vector2(canvas.x - 36.0 - 244.0, 36.0)


func _add_painted_control(stage: Control, node_name: String, group: String) -> PaintedBox:
	var rig: PaintedBox = PaintedBox.new()
	rig.name = node_name
	rig.add_to_group(group, false)
	stage.add_child(rig)
	return rig


func _add_group_control(stage: Control, node_name: String, group: String) -> Control:
	var control: Control = Control.new()
	control.name = node_name
	control.add_to_group(group, false)
	stage.add_child(control)
	return control


# ── BUG-013: the ratios are asserted on the character, not on the box ────────
#
# The box grows with the canvas because its height is a ratio, but the art inside
# it was fitted with `min(box.w/art.w, box.h/art.h)` against a fixed 640 px width,
# so on 4:3 the box was 0.574 of the height and the child was 0.418. A duck-typed
# double pins the oracle contract without depending on the rig's own fitting.


class PaintedBox:
	extends Control
	var painted: Rect2 = Rect2()

	func get_visual_global_rect() -> Rect2:
		return painted


func _add_painted_rig(stage: Control, box: Rect2, painted: Rect2) -> PaintedBox:
	var rig: PaintedBox = PaintedBox.new()
	rig.name = "Rig"
	rig.add_to_group(GeometryOracle.RIG_GROUP, false)
	rig.position = box.position
	rig.size = box.size
	rig.painted = painted
	stage.add_child(rig)
	return rig


func test_a_character_that_paints_smaller_than_its_box_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.IPAD_4_3, Vector2(148.0, 148.0))[1] as Control
	# The e02 geometry on 2048x1536: box 640x882 on the 78 % line, art 642 px tall.
	_add_painted_rig(
		stage,
		Rect2(704.0, 316.0, 640.0, 882.0),
		Rect2(703.0, 556.0, 642.0, 642.0),
	)
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.IPAD_4_3, GeometryOracle.CARE_ROOM_SPEC)

	assert_false(findings.is_empty(), "a 0.418 character behind a 0.574 box must fail")
	assert_true(oracle.summary().contains("painted character"), oracle.summary())
	assert_true(oracle.summary().contains("empty space"), oracle.summary())


func test_a_character_that_fills_its_box_passes() -> void:
	var stage: Control = _build_stage(GeometryOracle.IPAD_4_3, Vector2(148.0, 148.0))[1] as Control
	_add_edges(stage, GeometryOracle.IPAD_4_3)
	_add_painted_rig(
		stage,
		Rect2(694.0, 316.0, 660.0, 882.0),
		Rect2(694.0, 316.0, 660.0, 882.0),
	)
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.IPAD_4_3, GeometryOracle.CARE_ROOM_SPEC)

	assert_true(findings.is_empty(), oracle.summary())


func test_a_scene_that_forgets_a_declared_group_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.IPAD_4_3, Vector2(148.0, 148.0))[1] as Control
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	# CARE_ROOM_SPEC itself declares the three groups the care rooms must have.
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.IPAD_4_3, GeometryOracle.CARE_ROOM_SPEC)

	assert_eq(findings.size(), 3, "an empty declared group is a finding, not a silent pass: %s" % oracle.summary())
	assert_true(oracle.summary().contains("no such node"), oracle.summary())


func test_a_rig_that_cannot_report_painted_geometry_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.IPAD_4_3, Vector2(148.0, 148.0))[1] as Control
	_add_edges(stage, GeometryOracle.IPAD_4_3)
	# The pre-fix geometry with a node that cannot measure itself: this is exactly
	# the shape that shipped green (a tall box around a small character).
	var rig: Control = _add_group_control(stage, "Rig", GeometryOracle.RIG_GROUP)
	rig.position = Vector2(704.0, 316.0)
	rig.size = Vector2(640.0, 882.0)
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.IPAD_4_3, GeometryOracle.CARE_ROOM_SPEC)

	assert_false(findings.is_empty(), "a rig that cannot be measured must fail closed, not fall back to the box")
	assert_true(oracle.summary().contains("no painted geometry"), oracle.summary())


func test_an_oversized_scene_root_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.DESKTOP_16_9, Vector2(148.0, 148.0))[1] as Control
	stage.offset_right = 1920.0
	stage.offset_bottom = 1080.0
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.DESKTOP_16_9)

	assert_false(findings.is_empty(), "a 2x scene root must fail on its own")
	assert_true(oracle.summary().contains("scene root"), oracle.summary())


func test_a_rig_that_is_not_a_control_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.IPAD_4_3, Vector2(148.0, 148.0))[1] as Control
	_add_edges(stage, GeometryOracle.IPAD_4_3)
	var rig: Node2D = Node2D.new()
	rig.name = "Rig"
	rig.add_to_group(GeometryOracle.RIG_GROUP, false)
	stage.add_child(rig)
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.IPAD_4_3, GeometryOracle.CARE_ROOM_SPEC)

	assert_false(findings.is_empty(), "a Node2D in the rig group cannot be measured")
	assert_true(oracle.summary().contains("is not a Control"), oracle.summary())


func test_a_rig_whose_art_failed_to_load_is_caught() -> void:
	var stage: Control = _build_stage(GeometryOracle.IPAD_4_3, Vector2(148.0, 148.0))[1] as Control
	_add_edges(stage, GeometryOracle.IPAD_4_3)
	var rig: QuiQuiRig = QuiQuiRig.new()
	rig.name = "QuiQuiRig"
	rig.add_to_group(GeometryOracle.RIG_GROUP, false)
	stage.add_child(rig)
	await wait_frames(2)
	rig.expression.texture = null  # what a renamed or missing art file produces
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.IPAD_4_3, GeometryOracle.CARE_ROOM_SPEC)

	assert_false(findings.is_empty(), "missing art must not fall back to measuring the box")
	assert_true(oracle.summary().contains("no painted geometry"), oracle.summary())
