# story: e14s01
extends GutTest
## SC-e14s01 — the four care defs load with the templates the stories name.


func test_each_care_room_def_loads() -> void:
	for scene_id: String in ["bathroom", "closet", "playroom", "bedroom"]:
		var def: SceneDef = SceneDefLoader.load_by_id(scene_id)
		assert_not_null(def, scene_id)
		assert_eq(def.id, scene_id)
		assert_false(def.steps.is_empty())


func test_the_bathroom_chain_is_three_steps() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("bathroom")
	assert_eq(def.steps.size(), 3)
	assert_eq((def.steps[0] as StepDef).template_id, "t40_draw_fill")
	assert_eq((def.steps[1] as StepDef).template_id, "t23_erase")
	assert_eq((def.steps[2] as StepDef).template_id, "t23_erase")


func test_the_closet_lists_ten_pieces() -> void:
	var step: StepDef = SceneDefLoader.load_by_id("closet").steps[0] as StepDef
	assert_eq(step.template_id, "t45_dress_decorate")
	assert_eq(step.item_ids.size(), 10)


func test_the_playroom_counts_three_toys() -> void:
	var step: StepDef = SceneDefLoader.load_by_id("playroom").steps[0] as StepDef
	assert_eq(step.mode, "count_n")
	assert_eq(step.repeat_count, 3)
	assert_eq(step.item_ids, PackedStringArray(["ball", "pinwheel", "plush"]))


func test_the_bedroom_names_lamp_and_plush() -> void:
	var step: StepDef = SceneDefLoader.load_by_id("bedroom").steps[0] as StepDef
	assert_eq(step.item_ids, PackedStringArray(["lamp", "plush"]))
	assert_eq(step.repeat_count, 2)
