# story: e11s01
# story: e14s05
extends GutTest
## SC-E11-P0-01 — 500-step seeded walk across all 17 scenes; economy and FSM stay clean.

var walk: MbtWalk = null
var scene: Control = null


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()
	walk = MbtWalk.new()
	walk.reset()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _mount(scene_id: String) -> Control:
	var def: SceneDef = SceneDefLoader.load_by_id(scene_id)
	if def == null:
		return null
	var viewport: SubViewport = SubViewport.new()
	viewport.size = GeometryOracle.DESKTOP_16_9
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(SceneCatalog.PLAYER_SCENE) as PackedScene
	var player: ScenePlayer = packed.instantiate() as ScenePlayer
	player.manual_step = true
	player.def_override = def
	viewport.add_child(player)
	for _i: int in range(8):
		await wait_process_frames(1)
		if player.loaded_def != null:
			break
	return player


func _maybe_probe_fsm(root: Control) -> void:
	if root == null:
		return
	var fsm: Variant = root.get("fsm")
	if fsm is Fsm:
		var probe: FsmProbe = FsmProbe.new().attach(fsm as Fsm)
		assert_true(probe.is_clean(), probe.summary())
		probe.detach()


func test_five_hundred_steps_visit_every_scene_and_hold_invariants() -> void:
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_coins", 20)
	while walk.steps_done < MbtWalk.STEP_COUNT:
		var scene_id: String = walk.next_scene_id()
		scene = await _mount(scene_id)
		assert_not_null(scene, "mount %s" % scene_id)
		scene.set("manual_step", true)
		await wait_process_frames(2)
		_maybe_probe_fsm(scene)
		var faults: Array[String] = walk.assert_economy_invariants(progress)
		assert_true(faults.is_empty(), str(faults))
		walk.record_visit(scene_id)
		scene.queue_free()
		scene = null
	assert_eq(SceneCatalog.count(), SceneCatalog.SCENE_COUNT)
	assert_true(walk.all_scenes_visited(), "visited %d scenes" % walk.visited.size())
