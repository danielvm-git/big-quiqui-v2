# story: e13s02
extends GutTest
## SC-e13s02-P1-01..02. Tap reports distinct targets and never completes itself.

const SCRIPT_PATH: String = "res://scripts/components/tap_primitive.gd"


func test_any_completes_on_the_first_target() -> void:
	var tap: RefCounted = _new_tap("any", 3)
	if tap == null:
		return
	assert_true(bool(tap.call("note_tap", "apple")))
	assert_almost_eq(float(tap.call("progress")), 1.0, 0.001, "SC-e13s02-P1-01")
	var before: int = int(tap.call("reaction_count"))
	assert_false(bool(tap.call("note_tap", "apple")))
	assert_almost_eq(float(tap.call("progress")), 1.0, 0.001, "a repeat does not move progress")
	assert_gt(int(tap.call("reaction_count")), before, "a spent target still answers")
	assert_false(bool(tap.call("claims_completion")))


func test_count_n_counts_distinct_targets_only() -> void:
	var tap: RefCounted = _new_tap("count_n", 2)
	if tap == null:
		return
	assert_true(bool(tap.call("note_tap", "apple")))
	assert_almost_eq(float(tap.call("progress")), 0.5, 0.001)
	assert_false(bool(tap.call("note_tap", "apple")))
	assert_almost_eq(float(tap.call("progress")), 0.5, 0.001, "SC-e13s02-P1-02")
	assert_true(bool(tap.call("note_tap", "grape")))
	assert_almost_eq(float(tap.call("progress")), 1.0, 0.001)
	assert_eq(int(tap.call("seen_count")), 2)


func test_toggle_flips_and_persists_for_the_step() -> void:
	var tap: RefCounted = _new_tap("toggle", 2)
	if tap == null:
		return
	tap.call("note_tap", "lamp")
	assert_true(bool(tap.call("is_on", "lamp")))
	tap.call("note_tap", "plant")
	tap.call("note_tap", "lamp")
	assert_false(bool(tap.call("is_on", "lamp")))
	assert_true(bool(tap.call("is_on", "plant")), "the other target stays as it was")


func _new_tap(mode_name: String, goal: int) -> RefCounted:
	if not ResourceLoader.exists(SCRIPT_PATH):
		fail_test("missing %s" % SCRIPT_PATH)
		return null
	var script: Script = load(SCRIPT_PATH) as Script
	if script == null:
		fail_test("missing %s" % SCRIPT_PATH)
		return null
	var tap: RefCounted = script.new() as RefCounted
	tap.set("mode", mode_name)
	tap.set("goal", goal)
	return tap
