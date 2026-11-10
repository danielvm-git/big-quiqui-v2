# story: e14s01
# story: e14s05
extends GutTest
## SC-e14s01-P2-01 — bathroom hull is clean at both aspects on the player.

const PLAYER: String = "res://scenes/scene_player.tscn"


func before_each() -> void:
	TestReset.reset_all()


func test_bathroom_def_geometry_at_both_aspects() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("bathroom")
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var player: ScenePlayer = await _mount(def, size)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(player, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_eq(findings.size(), 0, str(findings))


func _scene_count() -> int:
	var dir: DirAccess = DirAccess.open("res://scenes")
	if dir == null:
		return 0
	var count: int = 0
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while not name.is_empty():
		if name.ends_with(".tscn"):
			count += 1
		name = dir.get_next()
	dir.list_dir_end()
	return count


func _mount(def: SceneDef, size: Vector2i) -> ScenePlayer:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var player: ScenePlayer = (load(PLAYER) as PackedScene).instantiate() as ScenePlayer
	player.manual_step = true
	player.def_override = def
	viewport.add_child(player)
	for _i: int in range(12):
		await wait_process_frames(1)
		if player.loaded_def != null:
			break
	return player
