# story: e14s03
extends GutTest


func test_bear_def_uses_four_slots() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("bear_puzzle")
	assert_not_null(def, "SC-e14s03-P0-03")
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t20_drag_snap")
	assert_eq(step.mode, "slots")
	assert_eq(step.repeat_count, 4)
