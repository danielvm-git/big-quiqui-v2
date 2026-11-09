# story: e13s08
extends GutTest
## SC-e13s08-P0-01. Lanes snap when the finger lifts, not while it moves.


func test_lanes_snap_on_release_only() -> void:
	var steer: RefCounted = _steer("lanes")
	steer.call("begin", Vector2(10.0, 20.0))
	steer.call("move_to", Vector2(160.0, 20.0))
	var mid: float = (steer.get("position") as Vector2).x
	assert_almost_eq(mid, 160.0, 0.001, "SC-e13s08-P0-01 mid-drag")
	assert_gt(absf(mid - 150.0), 1.0)
	steer.call("release")
	assert_almost_eq((steer.get("position") as Vector2).x, 150.0, 0.001)


func test_free_stays_where_the_finger_stopped() -> void:
	var steer: RefCounted = _steer("free")
	steer.call("begin", Vector2(10.0, 20.0))
	steer.call("move_to", Vector2(4000.0, -20.0))
	steer.call("release")
	var at: Vector2 = steer.get("position")
	assert_almost_eq(at.x, 300.0, 0.001, "clamped")
	assert_almost_eq(at.y, 0.0, 0.001)


func _steer(mode_name: String) -> RefCounted:
	var script: Script = load("res://scripts/components/steer_primitive.gd") as Script
	var steer: RefCounted = script.new() as RefCounted
	steer.set("mode", mode_name)
	steer.set("bounds", Rect2(0.0, 0.0, 300.0, 100.0))
	steer.set("lane_count", 3)
	return steer
