# story: e14s03
extends GutTest


func test_playhouse_def_loads_for_free_place() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("playhouse")
	assert_not_null(def, "SC-e14s03-P0-02")
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t45_dress_decorate")
	assert_eq(step.repeat_count, 5)
