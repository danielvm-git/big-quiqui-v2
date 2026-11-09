# story: e13s09
extends PlayerTestCase
## Review round 1 (A13) and round 3 (A3). Every template's tap surface is at least 120 px and a finger
## can reach it at the three canvases we ship: it is on screen and nothing above it takes the touch
## (`HitProbe`). Each def exposes a target of its own, so Home alone can never satisfy the check.

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
			assert_gt(_own_targets(player).size(), 0, "A3 %s at %s has a target besides Home" % [def_id, aspect])
			for target: Control in _targets(player):
				assert_true(
					target.size.x >= GeometryOracle.MIN_HIT_SIZE.x and target.size.y >= GeometryOracle.MIN_HIT_SIZE.y,
					"%s at %s: %s is at least 120 px" % [def_id, aspect, target.name]
				)
			assert_eq(_unreachable(player, aspect), [], "B8 %s at %s: every target can be reached" % [def_id, aspect])
			player.queue_free()
			await wait_process_frames(1)


func test_a_stop_control_above_a_target_fails_the_check() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("title_probe"))
	assert_eq(_unreachable(player, GeometryOracle.DESKTOP_16_9), [], "the verb is free")
	var cover: Control = Control.new()
	cover.name = "cover"
	cover.size = Vector2(1920.0, 1080.0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	player.add_child(cover)
	assert_has(_unreachable(player, GeometryOracle.DESKTOP_16_9), "play_button", "A3 a STOP sibling above is caught")


func test_a_target_that_no_finger_can_reach_fails_the_check() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("title_probe"))
	var lost: Control = Control.new()
	lost.name = "lost_target"
	lost.size = Vector2(120.0, 120.0)
	lost.position = Vector2(9000.0, 9000.0)
	lost.add_to_group(GeometryOracle.HIT_GROUP)
	player.add_child(lost)
	assert_eq(_unreachable(player, GeometryOracle.DESKTOP_16_9), ["lost_target"], "B8 the check is not vacuous")


## A target is lost when it is off screen after a scroll or a pan brings it in, or when a control above it
## takes the touch. A pin takes no touch itself: the map pad under it does, so the pad must be what answers.
func _unreachable(player: ScenePlayer, aspect: Vector2i) -> Array[String]:
	var lost: Array[String] = []
	var view: Rect2 = Rect2(Vector2.ZERO, Vector2(aspect))
	for target: Control in _targets(player):
		_bring_into_view(player, target)
		if not view.encloses(target.get_global_rect()) or not _answers(player, target):
			lost.append(target.name)
	return lost


func _answers(player: ScenePlayer, target: Control) -> bool:
	if target.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return HitProbe.answers(player, target)
	return HitProbe.top_at(player, target.get_global_rect().get_center()) is TouchPad


func _bring_into_view(player: ScenePlayer, target: Control) -> void:
	var strip: Node = _ancestor(target, ScrollContainer)
	if strip != null:
		(strip as ScrollContainer).ensure_control_visible(target)
	if target.get_parent() != null and target.get_parent().name == "MapWorld":
		(player.get("_template") as RefCounted).call("follow", target.position + target.size * 0.5)


func _ancestor(node: Node, kind: Variant) -> Node:
	var parent: Node = node.get_parent()
	while parent != null:
		if is_instance_of(parent, kind):
			return parent
		parent = parent.get_parent()
	return null


func _own_targets(player: ScenePlayer) -> Array[Control]:
	var found: Array[Control] = []
	for target: Control in _targets(player):
		if target.name != "HomeButton":
			found.append(target)
	return found


func _targets(player: ScenePlayer) -> Array[Control]:
	var found: Array[Control] = []
	for node: Node in player.get_tree().get_nodes_in_group(GeometryOracle.HIT_GROUP):
		if node is Control and player.is_ancestor_of(node) and not node.is_queued_for_deletion():
			found.append(node as Control)
	return found
