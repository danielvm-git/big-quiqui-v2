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
	pan.call("begin", Vector2(100.0, 100.0), 0, true)
	pan.call("move_to", Vector2(110.0, 100.0))
	assert_true(bool(pan.call("end_allows_tap")), "under tolerance still taps")
	pan.call("begin", Vector2(100.0, 100.0), 0, true)
	pan.call("move_to", Vector2(160.0, 100.0))
	assert_false(bool(pan.call("end_allows_tap")), "SC-e13s03-P0-02")


func test_a_press_on_a_target_never_pans() -> void:
	var pan: RefCounted = _new_pan()
	pan.set("world_size", Vector2(3000.0, 1080.0))
	pan.call("begin", Vector2(100.0, 100.0), 0, true)
	pan.call("move_to", Vector2(160.0, 100.0))
	assert_eq(pan.get("offset"), Vector2.ZERO, "B6 the target press holds still")
	assert_eq(str(pan.call("state_id")), "HELD")


func test_one_finger_owns_the_gesture_until_it_lifts() -> void:
	var pan: RefCounted = _new_pan()
	pan.set("world_size", Vector2(3000.0, 1080.0))
	assert_true(bool(pan.call("begin", Vector2(100.0, 100.0), 7)))
	assert_false(bool(pan.call("begin", Vector2(900.0, 100.0), 8)), "a second finger is refused")
	pan.call("move_to", Vector2(900.0, 100.0), 8)
	assert_eq(pan.get("offset"), Vector2.ZERO, "a stranger's move is ignored")
	assert_false(bool(pan.call("end_allows_tap", 8)), "a stranger's lift is ignored")
	assert_eq(str(pan.call("state_id")), "PANNING", "the owner still holds it")
	pan.call("move_to", Vector2(40.0, 100.0), 7)
	assert_almost_eq((pan.get("offset") as Vector2).x, 60.0, 0.001, "the owner pans")
	assert_false(bool(pan.call("end_allows_tap", 7)), "a pan lift is not a tap")
	assert_eq(str(pan.call("state_id")), "IDLE")


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


func test_the_gesture_has_a_declared_empty_dwell_table() -> void:
	assert_true(PanPrimitive.MAX_DWELL_SEC.is_empty(), "B6 a child-owned gesture has no deadline, said on purpose")
	assert_eq(PanPrimitive.MAX_DWELL_SEC.size(), 0)


func test_a_slide_that_starts_on_a_target_pans_and_a_short_one_still_taps() -> void:
	var pan: RefCounted = _new_pan()
	if pan == null:
		return
	pan.set("world_size", Vector2(3000.0, 1080.0))
	pan.set("view_size", Vector2(1920.0, 1080.0))
	pan.set("tolerance", 24.0)
	pan.call("begin", Vector2(500.0, 100.0), 0, true, true)
	pan.call("move_to", Vector2(400.0, 100.0))
	assert_almost_eq((pan.get("offset") as Vector2).x, 100.0, 0.001, "A8 a press on a target still pans")
	assert_false(bool(pan.call("end_allows_tap")), "A8 a long slide is not a tap")
	pan.call("begin", Vector2(500.0, 100.0), 0, true, true)
	pan.call("move_to", Vector2(495.0, 100.0))
	assert_true(bool(pan.call("end_allows_tap")), "A8 a short slide is still a tap")
	assert_eq(pan.call("state_id"), "IDLE")
