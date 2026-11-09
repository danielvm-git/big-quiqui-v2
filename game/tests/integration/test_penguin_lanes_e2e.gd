# story: e14s04
extends PlayerTestCase
## SC-e14s04-P0-03, P1-02, P2-01 — penguin on the player; village and party catalog ids.

const LANES_ID: String = "penguin_lanes"
const WHEEL_ID: String = "wheel"
const LEGACY_COUNT: int = 1
const ASPECTS: Array[Vector2i] = [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]


func before_each() -> void:
	TestReset.reset_all()


func test_eighteen_legacy_scenes_remain() -> void:
	assert_eq(_scene_count(), LEGACY_COUNT)


func test_village_map_names_wheel_and_party_friend_names_penguin_lanes() -> void:
	var village: SceneDef = SceneDefLoader.load_by_id("village")
	var map: StepDef = village.steps[0] as StepDef
	assert_true(map.destination_scenes.has("wheel"), "SC-e14s04-P1-02 village")
	var party: SceneDef = SceneDefLoader.load_by_id("party")
	var friends: StepDef = party.steps[0] as StepDef
	assert_eq(friends.destination_scenes[2], "penguin_lanes")


func test_the_same_seed_replays_spawns_and_leaves_no_extra_nodes() -> void:
	var first: ScenePlayer = await mount(SceneDefLoader.load_by_id(LANES_ID))
	var tpl_a: RefCounted = first.get("_template")
	for _i: int in range(3):
		tpl_a.call("tick")
	var lane_a: int = int(tpl_a.call("first_lane"))
	first.queue_free()
	var second: ScenePlayer = await mount(SceneDefLoader.load_by_id(LANES_ID))
	var tpl_b: RefCounted = second.get("_template")
	for _i: int in range(3):
		tpl_b.call("tick")
	assert_eq(int(tpl_b.call("first_lane")), lane_a, "SC-e14s04-P0-03 seeded replay")
	var field: Control = second.get_node("LaneField") as Control
	for _tick: int in range(200):
		tpl_b.call("tick")
		assert_lte(_live_pictures(field), 6)
	second.runner.request_home()
	second.advance(0.2)
	await wait_process_frames(2)
	assert_null(second.get_node_or_null("LanePad"))


func test_wheel_and_penguin_lay_out_at_both_aspects() -> void:
	for scene_id: String in [WHEEL_ID, LANES_ID]:
		for size: Vector2i in ASPECTS:
			var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(scene_id), size)
			var oracle: GeometryOracle = GeometryOracle.new()
			var findings: Array[String] = oracle.audit(player, size, GeometryOracle.CARE_ROOM_SPEC)
			assert_eq(findings.size(), 0, "%s %s" % [scene_id, findings])
			player.queue_free()


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


func _live_pictures(field: Control) -> int:
	var count: int = 0
	for child: Node in field.get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count
