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
