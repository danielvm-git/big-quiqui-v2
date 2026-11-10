# story: e14s02
extends GutTest
## SC-e14s02-P0-01..04. Hub defs exist and reject foreign destinations.


func before_each() -> void:
	TestReset.reset_all()


func test_title_home_village_and_celebration_defs_load() -> void:
	for scene_id: String in ["title", "home", "village", "celebration"]:
		assert_not_null(SceneDefLoader.load_by_id(scene_id), scene_id)


func test_title_requests_home_with_one_verb() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("title")
	assert_not_null(def)
	assert_eq(def.next_scene_id, "home")
	assert_eq((def.steps[0] as StepDef).template_id, "t0_title")
