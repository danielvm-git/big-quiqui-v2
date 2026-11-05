# story: e01s05
extends GutTest
## SC-E01-P1-07/08 — the first playable slice: `titulo.tscn` boots, the Play
## button is the only way in and it is tappable without reading, and the layout
## holds on both a 16:9 desktop window and a 4:3 iPad.

const SCENE_PATH: String = "res://scenes/titulo.tscn"

var scene: TituloScene = null


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null
	get_node("/root/AudioManager").reset()


func _mount(size: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)

	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_not_null(packed, "titulo.tscn must load")
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


# SC-E01-P1-08
func test_both_aspects_pass_the_geometry_oracle() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		var stage: Control = _mount(size)
		await wait_frames(3)

		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(stage, size)
		assert_true(findings.is_empty(), "%dx%d: %s" % [size.x, size.y, oracle.summary()])

		stage.get_parent().queue_free()


# SC-E01-P1-07
func test_the_scene_has_a_rig_that_is_alive_and_a_giant_play_button() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as TituloScene
	await wait_frames(3)

	assert_not_null(scene.rig, "the rig must be in the scene")
	assert_true(scene.rig.get_visual_global_rect().has_area(), "QuiQui is visible")
	assert_not_null(scene.play_button, "the Play button must be in the scene")

	var box: Rect2 = scene.play_button.get_global_rect()
	assert_true(box.size.x >= 120.0 and box.size.y >= 120.0, "hit target is %s" % box.size)
	assert_true(scene.play_button.is_in_group(GeometryOracle.HIT_GROUP))


# SC-E01-P1-07
func test_tapping_play_fires_once_and_does_not_crash_without_the_next_scene() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as TituloScene
	await wait_frames(3)
	var requested: Array[bool] = []
	scene.play_requested.connect(func() -> void: requested.append(true))

	for event: InputEvent in TouchSim.tap_events(scene.play_button, true):
		scene.play_button._gui_input(event)

	assert_eq(requested.size(), 1, "one tap, one request")
	assert_eq(scene.play_presses, 1)
	assert_true(scene.is_inside_tree(), "casa.tscn does not exist yet — the scene stays up")


func test_the_main_theme_starts_with_the_scene() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as TituloScene
	await wait_frames(3)

	assert_true(scene.music_started, "tema_principal.ogg must start on the title screen")


func test_tapping_quiqui_makes_her_laugh() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as TituloScene
	await wait_frames(3)

	for event: InputEvent in TouchSim.tap_events(scene.rig, true):
		scene.rig._gui_input(event)

	assert_eq(scene.rig.expression_id, "rindo", "affection gets a reaction")
	assert_eq(scene.rig.taps, 1, "and the echo does not double count")
