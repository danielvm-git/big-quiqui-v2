# story: e13s08
extends PlayerTestCase
## SC-e13s08-P0-03..04. Lanes are played through the player: spawn, steer, catch, leave, no orphans.

const PROBE: String = "penguin_probe"


func before_each() -> void:
	TestReset.reset_all()


func _pad(player: ScenePlayer) -> TouchPad:
	return player.get_node("LanePad") as TouchPad


func _ticks(player: ScenePlayer, count: int) -> void:
	for _i: int in range(count):
		player.advance(0.61)


func _lane_point(player: ScenePlayer, lane: int) -> Vector2:
	var field: Control = player.get_node("LaneField") as Control
	var width: float = field.size.x / 3.0
	return field.global_position + Vector2(width * (float(lane) + 0.5), 800.0)


func test_the_player_ticks_the_template_and_items_appear_as_nodes() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	assert_not_null(_pad(player), "A4 the lanes have a touch surface")
	_ticks(player, 2)
	var field: Control = player.get_node("LaneField") as Control
	assert_gt(field.get_child_count(), 1, "A4 spawned items are drawn (basket plus items)")


func test_a_finger_over_a_lane_catches_what_fell_there() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	_ticks(player, 1)
	var tpl: RefCounted = player.get("_template")
	var lane: int = int(tpl.call("first_lane"))
	assert_gte(lane, 0)
	var at: Vector2 = _lane_point(player, lane)
	send(_pad(player), touch(at - Vector2(300.0, 0.0), true))
	send(_pad(player), drag(at))
	send(_pad(player), touch(at, false))
	assert_gt(int(tpl.call("score")), 0, "SC-e13s08-P0-03 a catch scores")


func test_a_second_finger_and_the_mouse_echo_do_not_steer() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	var tpl: RefCounted = player.get("_template")
	var first: Vector2 = _lane_point(player, 0)
	send(_pad(player), touch(first, true, 1))
	send(_pad(player), drag(_lane_point(player, 2), 2))
	send(_pad(player), drag(_lane_point(player, 2), 1, -1))
	send(_pad(player), touch(_lane_point(player, 2), false, 2))
	assert_eq(int(tpl.call("basket_lane")), 0, "B6 only the first finger steers")


func test_a_miss_is_quiet_and_nothing_is_lost() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	_ticks(player, 12)
	var tpl: RefCounted = player.get("_template")
	assert_gt(int(tpl.call("misses")), 0)
	assert_eq(int(tpl.call("score")), 0)
	assert_true(player.runner.fsm.state == StepRunner.STATE_STEP, "the step goes on")


func test_leaving_the_step_frees_every_node_the_template_made() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	var before: int = player.get_child_count()  # includes the template pad and field
	_ticks(player, 6)
	assert_gt(player.get_node("LaneField").get_child_count(), 0)
	player.runner.request_home()
	player.advance(0.2)
	await wait_process_frames(2)
	assert_null(player.get_node_or_null("LanePad"))
	assert_null(player.get_node_or_null("LaneField"))
	assert_eq(player.get_child_count(), before - 2, "SC-e13s08-P0-04 the pad and the field left, nothing else stayed")
