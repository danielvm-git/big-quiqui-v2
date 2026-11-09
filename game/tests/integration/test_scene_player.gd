# story: e12s02
# story: e12s03
extends GutTest
## SC-e12s02-P0-07, SC-e12s03-P0-04, P1-01, P2-02

const PLAYER_PATH: String = "res://scenes/scene_player.tscn"


func before_each() -> void:
	TestReset.reset_all()


func test_the_player_boots_from_a_consumed_def() -> void:
	var sm: Node = get_node("/root/SceneManager")
	sm.manual_step = true
	sm.reset()
	sm.fade_duration_sec = 0.1
	sm.loader = Callable()
	sm.production_swap = Callable()
	sm.set_test_mode(true)
	assert_true(sm.request_def("dev_smoke"))
	while sm.is_busy():
		sm.advance(0.1)
	var packed: PackedScene = load(PLAYER_PATH) as PackedScene
	assert_not_null(packed)
	var player: ScenePlayer = packed.instantiate() as ScenePlayer
	assert_not_null(player)
	add_child_autofree(player)
	player.manual_step = true
	player.boot_from_manager()
	assert_not_null(player.loaded_def)
	assert_eq(player.loaded_def.id, "dev_smoke")
	sm.reset()
	sm.manual_step = false


func test_dot_count_matches_step_count() -> void:
	var player: ScenePlayer = await _mount_factory_def()
	player.advance(0.0)
	var dots: CareDotsBar = player.get_node("StepDots") as CareDotsBar
	assert_eq(dots.dot_count(), player.loaded_def.steps.size())


func test_geometry_oracle_passes_on_both_aspects() -> void:
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var player: ScenePlayer = await _mount_factory_def(size)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(player, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_eq(findings.size(), 0, str(findings))


func test_load_to_exit_has_no_extra_template_nodes() -> void:
	var player: ScenePlayer = await _mount_factory_def()
	var before: int = player.get_child_count()
	player.advance(0.2)
	for _i: int in range(3):
		player.advance(0.2)
	player.runner.request_home()
	player.advance(0.2)
	assert_eq(player.get_child_count(), before)


func _mount_factory_def(size: Vector2i = GeometryOracle.DESKTOP_16_9) -> ScenePlayer:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(PLAYER_PATH) as PackedScene
	var player: ScenePlayer = packed.instantiate() as ScenePlayer
	player.manual_step = true
	player.def_override = SceneDefFactory.valid()
	viewport.add_child(player)
	for _i: int in range(10):
		await wait_process_frames(1)
		if player.loaded_def != null:
			break
	return player
