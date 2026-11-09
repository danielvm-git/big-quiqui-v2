# story: e12s06
extends GutTest
## SC-e12s06-P0-04..05, P2-01

const PLAYER_PATH: String = "res://scenes/scene_player.tscn"


func before_each() -> void:
	TestReset.reset_all()


func _mount(def: SceneDef, size: Vector2i) -> ScenePlayer:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(PLAYER_PATH) as PackedScene
	var player: ScenePlayer = packed.instantiate() as ScenePlayer
	player.manual_step = true
	player.def_override = def
	viewport.add_child(player)
	for _i: int in range(10):
		await wait_process_frames(1)
		if player.loaded_def != null:
			break
	assert_not_null(player.loaded_def)
	assert_eq(player.runner.fsm.state, StepRunner.STATE_STEP)
	return player


func test_three_feeds_credit_feed_once() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	var def: SceneDef = SceneDefLoader.load_by_id("kitchen")
	var player: ScenePlayer = await _mount(def, GeometryOracle.DESKTOP_16_9)
	var probe: FsmProbe = FsmProbe.new().attach(clm.fsm)
	assert_eq(player.template_draggables().size(), 3)
	for item: TouchDraggable in player.template_draggables():
		item.consumed.emit()
		player.advance(0.1)
	assert_almost_eq(player.runner.template_progress(), 1.0, 0.001)
	player.advance(0.2)
	for _i: int in range(40):
		player.advance(0.1)
		if player.runner.fsm.state == StepRunner.STATE_EXIT:
			break
	assert_eq(clm.state_id(), CareSteps.BATH)
	assert_true(probe.is_clean(), probe.summary())
	probe.detach()


func test_reentry_after_feed_credits_nothing() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	clm.call("begin_step", CareSteps.FEED)
	clm.call("complete_step", CareSteps.FEED)
	var def: SceneDef = SceneDefLoader.load_by_id("kitchen")
	var player: ScenePlayer = await _mount(def, GeometryOracle.DESKTOP_16_9)
	for _i: int in range(40):
		player.advance(0.05)
		for item: TouchDraggable in player.template_draggables():
			item.consumed.emit()
	assert_eq(clm.completed_steps(), 1)


func test_kitchen_geometry_at_both_aspects() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("kitchen")
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var player: ScenePlayer = await _mount(def, size)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(player, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_eq(findings.size(), 0, str(findings))
