# story: e13s03
extends GutTest
## SC-e13s03-P0-01..02. Pan clamps to the world and a long drag cancels the tap.

const SCRIPT_PATH: String = "res://scripts/components/pan_primitive.gd"


func test_pan_clamps_at_both_edges() -> void:
	var pan: RefCounted = _new_pan()
	if pan == null:
		return
	pan.set("world_size", Vector2(3000.0, 1080.0))
	pan.set("view_size", Vector2(1920.0, 1080.0))
	pan.call("drag_by", Vector2(-400.0, -80.0))
	assert_eq((pan.get("offset") as Vector2).x, 0.0, "SC-e13s03-P0-01 left")
	assert_eq((pan.get("offset") as Vector2).y, 0.0, "SC-e13s03-P0-01 top")
	pan.call("drag_by", Vector2(5000.0, 500.0))
	assert_almost_eq((pan.get("offset") as Vector2).x, 1080.0, 0.001, "SC-e13s03-P0-01 right")
	assert_eq((pan.get("offset") as Vector2).y, 0.0, "no vertical slack")


func test_a_long_drag_cancels_the_tap() -> void:
	var pan: RefCounted = _new_pan()
	if pan == null:
		return
	pan.set("tolerance", 24.0)
	pan.call("begin", Vector2(100.0, 100.0))
	pan.call("move_to", Vector2(110.0, 100.0))
	assert_true(bool(pan.call("end_allows_tap")), "under tolerance still taps")
	pan.call("begin", Vector2(100.0, 100.0))
	pan.call("move_to", Vector2(160.0, 100.0))
	assert_false(bool(pan.call("end_allows_tap")), "SC-e13s03-P0-02")


func test_follow_scrolls_to_a_target_and_clamps() -> void:
	var pan: RefCounted = _new_pan()
	if pan == null:
		return
	pan.set("world_size", Vector2(3000.0, 1080.0))
	pan.set("view_size", Vector2(1920.0, 1080.0))
	pan.call("follow", Vector2(2900.0, 540.0))
	assert_almost_eq((pan.get("offset") as Vector2).x, 1080.0, 0.001, "follow clamps")


func _new_pan() -> RefCounted:
	if not ResourceLoader.exists(SCRIPT_PATH):
		fail_test("missing %s" % SCRIPT_PATH)
		return null
	var script: Script = load(SCRIPT_PATH) as Script
	if script == null:
		fail_test("missing %s" % SCRIPT_PATH)
		return null
	return script.new() as RefCounted
