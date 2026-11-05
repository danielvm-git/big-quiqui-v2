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
	var rig: Control = _add_group_control(stage, "Rig", GeometryOracle.RIG_GROUP)
	rig.position = Vector2(640.0, 222.0)
	rig.size = Vector2(640.0, 400.0)
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
	var rig: Control = _add_group_control(stage, "Rig", GeometryOracle.RIG_GROUP)
	# 620 / 1080 of the height, feet on 78 %, centred: the ADR-008 contract.
	rig.anchor_left = 0.5
	rig.anchor_right = 0.5
	rig.anchor_top = 0.78 - 620.0 / 1080.0
	rig.anchor_bottom = 0.78
	rig.offset_left = -320.0
	rig.offset_right = 320.0
	await wait_frames(2)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, GeometryOracle.IPAD_4_3, GeometryOracle.CARE_ROOM_SPEC)

	assert_true(findings.is_empty(), oracle.summary())


func _add_group_control(stage: Control, node_name: String, group: String) -> Control:
	var control: Control = Control.new()
	control.name = node_name
	control.add_to_group(group, false)
	stage.add_child(control)
	return control
