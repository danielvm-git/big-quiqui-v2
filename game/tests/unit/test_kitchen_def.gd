# story: e12s06
extends GutTest
## SC-e12s06-P0-03 — kitchen.tres declares what t20 reads.

const REQUIRED: Array[String] = [
	"repeat_count",
	"mode",
	"receiver_id",
	"item_ids",
	"on_hit_pose",
	"on_hit_sfx_id",
	"care_step_id",
]


func test_kitchen_def_loads_and_declares_template_fields() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("kitchen")
	assert_not_null(def)
	assert_eq(def.id, "kitchen")
	assert_eq(def.steps.size(), 1)
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t20_drag_snap")
	for field: String in REQUIRED:
		assert_true(_step_has(step, field), field)


func _step_has(step: StepDef, field: String) -> bool:
	var ok: bool = false
	if field == "repeat_count":
		ok = step.repeat_count > 0
	elif field == "mode":
		ok = not step.mode.is_empty()
	elif field == "receiver_id":
		ok = not step.receiver_id.is_empty()
	elif field == "item_ids":
		ok = step.item_ids.size() > 0
	elif field == "on_hit_pose":
		ok = not step.on_hit_pose.is_empty()
	elif field == "on_hit_sfx_id":
		ok = not step.on_hit_sfx_id.is_empty()
	elif field == "care_step_id":
		ok = step.care_step_id == CareSteps.FEED
	return ok
