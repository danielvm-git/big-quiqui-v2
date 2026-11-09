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
	for rub: String in ["t23_erase", "t40_draw_fill"]:
		var wrong: StepDef = _step(rub)
		wrong.mode = "reveal"
		assert_eq(StepParams.problem(wrong), "bad_mode", "%s does not reveal" % rub)
	var chain: StepDef = _step("t34_rub_reveal")
	chain.mode = "clear"
	assert_eq(StepParams.problem(chain), "bad_mode")


func test_every_t21_mode_loads_and_a_def_with_no_mode_is_any() -> void:
	for mode: String in ["any", "count_n", "toggle", "single"]:
		var step: StepDef = _step("t21_touch_each")
		step.mode = mode
		assert_eq(StepParams.problem(step), "", mode)
	var def: SceneDef = SceneDef.new()
	def.id = "mode_less"
	def.background_id = "bg_playroom"
	def.next_scene_id = "home"
	var bare: StepDef = _step("t21_touch_each")
	bare.item_ids = PackedStringArray(["apple", "grape"])
	def.steps = [bare] as Array[Resource]
	assert_not_null(SceneDefLoader.validate(def), "A1 a count_n or mode-less def passes the loader")
	bare.mode = "count_n"
	assert_not_null(SceneDefLoader.validate(def))


func test_a_step_with_nothing_to_tap_show_or_catch_never_loads() -> void:
	for template: String in ["t21_touch_each", "t34_rub_reveal", "t45_dress_decorate", "t50_lanes", "t51_prize_pick"]:
		var step: StepDef = _step(template)
		step.item_ids = PackedStringArray()
		assert_eq(StepParams.problem(step), "no_items", template)


func test_a_slot_may_repeat_but_an_item_may_not() -> void:
	var step: StepDef = _step("t45_dress_decorate")
	step.item_ids = PackedStringArray(["blue_scarf", "red_scarf"])
	step.slot_ids = PackedStringArray(["neck", "neck"])
	assert_eq(StepParams.problem(step), "", "A2 two neck items share one slot")
	step.item_ids = PackedStringArray(["blue_scarf", "blue_scarf"])
	assert_eq(StepParams.problem(step), "bad_id")
	var map: StepDef = _map()
	map.destination_scenes = PackedStringArray(["kitchen", "kitchen"])
	assert_eq(StepParams.problem(map), "", "two doors may open one room")


func test_a_door_outside_the_world_and_a_wild_tolerance_are_rejected() -> void:
	var step: StepDef = _map()
	step.destination_positions = PackedVector2Array([Vector2(1.0, 1.0), Vector2(99999.0, 2.0)])
	assert_eq(StepParams.problem(step), "bad_world", "B2 a door nobody can reach")
	step = _map()
	step.pan_tolerance = 1.0e9
	assert_eq(StepParams.problem(step), "bad_number", "A19 a drag must be able to cancel a tap")


func test_per_item_poses_pair_with_items_and_use_the_grammar() -> void:
	var step: StepDef = _step("t21_touch_each")
	step.hit_poses = PackedStringArray(["pleased", ""])
	assert_eq(StepParams.problem(step), "mismatched_arrays")
	step.item_ids = PackedStringArray(["apple", "grape"])
	assert_eq(StepParams.problem(step), "")
	step.hit_poses = PackedStringArray(["pleased", "Bad Pose"])
	assert_eq(StepParams.problem(step), "bad_id")


func test_the_rub_grid_edge_is_bounded() -> void:
	var step: StepDef = _step("t23_erase")
	step.param_int = 500
	assert_eq(StepParams.problem(step), "bad_count")
	step.param_int = 3
	assert_eq(StepParams.problem(step), "")


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
	step.item_ids = PackedStringArray(["apple"])
	return step


func _map() -> StepDef:
	var step: StepDef = _step("t25_map")
	step.destination_ids = PackedStringArray(["a_door", "b_door"])
	step.destination_scenes = PackedStringArray(["kitchen", "bathroom"])
	step.destination_locks = PackedStringArray(["", "FEED"])
	step.destination_positions = PackedVector2Array([Vector2(1.0, 1.0), Vector2(2.0, 2.0)])
	return step
