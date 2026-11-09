# story: e14s03
extends PlayerTestCase
## SC-e14s03-P2-01 — village room defs lay out at both aspects.

const LEGACY_COUNT: int = 1


func before_each() -> void:
	TestReset.reset_all()


func test_eighteen_legacy_scenes_remain() -> void:
	assert_eq(_scene_count(), LEGACY_COUNT)


func test_playhouse_geometry_at_both_aspects() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("playhouse")
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var player: ScenePlayer = await mount(def, size)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(player, size, GeometryOracle.CARE_ROOM_SPEC)
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
