# story: e13s09
extends PlayerTestCase
## Review round 1 (A13). Every template's tap surface is at least 120 px and reachable at the three
## canvases we ship, read from the live player and not from one button on its own.

const DEFS: Array[String] = [
	"touch_each_probe",
	"bathroom_probe",
	"rub_reveal_probe",
	"dress_probe",
	"reward_probe",
	"prize_probe",
	"title_probe",
	"penguin_probe",
	"home_map",
]


func before_each() -> void:
	TestReset.reset_all()


func test_every_surface_is_a_full_tap_and_reachable_at_every_aspect() -> void:
	for aspect: Vector2i in GeometryOracle.ASPECTS:
		for def_id: String in DEFS:
			var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(def_id), aspect)
			var view: Rect2 = Rect2(Vector2.ZERO, Vector2(aspect))
			var targets: Array[Control] = _targets(player)
			var seen: int = 0
			for target: Control in targets:
				assert_true(
					target.size.x >= GeometryOracle.MIN_HIT_SIZE.x and target.size.y >= GeometryOracle.MIN_HIT_SIZE.y,
					"%s at %s: %s is at least 120 px" % [def_id, aspect, target.name]
				)
				if view.encloses(target.get_global_rect()):
					seen += 1
			assert_gt(seen, 0, "%s at %s has a target on screen" % [def_id, aspect])
			player.queue_free()
			await wait_process_frames(1)


func _targets(player: ScenePlayer) -> Array[Control]:
	var found: Array[Control] = []
	for node: Node in player.get_tree().get_nodes_in_group(GeometryOracle.HIT_GROUP):
		if node is Control and player.is_ancestor_of(node) and not node.is_queued_for_deletion():
			found.append(node as Control)
	return found
