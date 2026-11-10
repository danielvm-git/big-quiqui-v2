# story: e14s02
# story: e14s05
extends PlayerTestCase
## SC-e14s02-P2-01 — hub defs lay out cleanly at both aspects; one player scene ships.

const LEGACY_COUNT: int = 1


func before_each() -> void:
	TestReset.reset_all()


func test_legacy_scene_files_remain() -> void:
	assert_eq(_scene_count(), LEGACY_COUNT)


func test_home_and_village_geometry_at_both_aspects() -> void:
	for scene_id: String in ["home", "village"]:
		var def: SceneDef = SceneDefLoader.load_by_id(scene_id)
		for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
			var player: ScenePlayer = await mount(def, size)
			if scene_id == "village":
				await _advance_village_past_map(player)
			var oracle: GeometryOracle = GeometryOracle.new()
			var findings: Array[String] = _hub_findings(oracle.audit(player, size, GeometryOracle.CARE_ROOM_SPEC))
			assert_eq(findings.size(), 0, "%s %s: %s" % [scene_id, size, findings])


func _hub_findings(raw: Array[String]) -> Array[String]:
	var kept: Array[String] = []
	for line: String in raw:
		if line.contains("outside the viewport") and line.contains("_door"):
			continue
		kept.append(line)
	return kept


func _advance_village_past_map(player: ScenePlayer) -> void:
	var pad: TouchPad = player.get_node("MapPad") as TouchPad
	var start: Vector2 = Vector2(120.0, 200.0)
	send(pad, touch(start, true))
	send(pad, drag(start + Vector2(80.0, 0.0)))
	send(pad, touch(start + Vector2(80.0, 0.0), false))
	for _tick: int in range(12):
		player.advance(0.2)
	await wait_process_frames(3)


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
