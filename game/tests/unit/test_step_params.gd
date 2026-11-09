# story: e13s09
extends GutTest
## Review round 1 (B7). A def with malformed template parameters is rejected, and every def we ship passes.


func test_every_shipped_def_passes() -> void:
	var dir: DirAccess = DirAccess.open(SceneDefLoader.DATA_DIR)
	for file: String in dir.get_files():
		if file.ends_with(".tres"):
			assert_not_null(SceneDefLoader.load_by_id(file.get_basename()), file)


func test_a_bad_threshold_is_rejected() -> void:
	for bad: float in [0.0, 1.5, NAN, INF, -0.2]:
		var step: StepDef = _step("t23_erase")
		step.completion_threshold = bad
		assert_eq(StepParams.problem(step), "bad_threshold", str(bad))
	assert_eq(StepParams.problem(_step("t23_erase")), "")


func test_a_map_with_unequal_arrays_is_rejected() -> void:
	var step: StepDef = _map()
	step.destination_scenes = PackedStringArray(["kitchen"])
	assert_eq(StepParams.problem(step), "mismatched_arrays")
	step = _map()
	step.destination_locks = PackedStringArray(["FEED"])
	assert_eq(StepParams.problem(step), "mismatched_arrays")
	step = _map()
	step.destination_positions = PackedVector2Array([Vector2.ZERO])
	assert_eq(StepParams.problem(step), "mismatched_arrays")
	assert_eq(StepParams.problem(_map()), "")


func test_a_map_world_must_be_finite_and_positive() -> void:
	for size: Vector2 in [Vector2.ZERO, Vector2(-1.0, 10.0), Vector2(NAN, 10.0), Vector2(1.0e9, 10.0)]:
		var step: StepDef = _map()
		step.world_size = size
		assert_eq(StepParams.problem(step), "bad_world", str(size))


func test_ids_must_use_the_grammar_and_not_repeat() -> void:
	var step: StepDef = _step("t21_touch_each")
	step.item_ids = PackedStringArray(["Apple"])
	assert_eq(StepParams.problem(step), "bad_id")
	step.item_ids = PackedStringArray(["apple", "apple"])
	assert_eq(StepParams.problem(step), "bad_id", "a duplicate id leaks a button")
	step.item_ids = PackedStringArray(["apple", "grape"])
	assert_eq(StepParams.problem(step), "")


func test_a_lock_must_name_a_care_step_in_capitals() -> void:
	var step: StepDef = _map()
	step.destination_locks = PackedStringArray(["", "feed; drop"])
	assert_eq(StepParams.problem(step), "bad_id")


func test_an_unsupported_mode_is_rejected() -> void:
	var step: StepDef = _step("t21_touch_each")
	step.mode = "teleport"
	assert_eq(StepParams.problem(step), "bad_mode")


func test_lane_and_spawn_numbers_are_bounded() -> void:
	for field: String in ["lane_count", "spawn_cadence", "spawn_lifetime", "goal_count"]:
		var step: StepDef = _step("t50_lanes")
		step.set(field, 0)
		assert_eq(StepParams.problem(step), "bad_count", field)
	assert_eq(StepParams.problem(_step("t50_lanes")), "")


func test_dress_slots_must_match_items() -> void:
	var step: StepDef = _step("t45_dress_decorate")
	step.item_ids = PackedStringArray(["blue_scarf", "crown"])
	step.slot_ids = PackedStringArray(["neck"])
	assert_eq(StepParams.problem(step), "mismatched_arrays")


func test_the_loader_rejects_and_logs_a_bad_step() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("home_map")
	var step: StepDef = def.steps[0] as StepDef
	step.destination_scenes = PackedStringArray(["kitchen"])
	assert_null(SceneDefLoader.validate(def))


func _step(template_id: String) -> StepDef:
	var step: StepDef = StepDef.new()
	step.template_id = template_id
	step.mode = "any"
	return step


func _map() -> StepDef:
	var step: StepDef = _step("t25_map")
	step.destination_ids = PackedStringArray(["a_door", "b_door"])
	step.destination_scenes = PackedStringArray(["kitchen", "bathroom"])
	step.destination_locks = PackedStringArray(["", "FEED"])
	step.destination_positions = PackedVector2Array([Vector2(1.0, 1.0), Vector2(2.0, 2.0)])
	return step
