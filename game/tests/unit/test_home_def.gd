# story: e14s02
extends GutTest
## SC-e14s02-P0-02 and P1-01 — catalog ids only; locks dim without a wallet.


func before_each() -> void:
	TestReset.reset_all()


func test_home_def_lists_six_shipped_destinations() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("home")
	assert_not_null(def)
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t25_map")
	assert_eq(step.destination_scenes.size(), 6)
	for scene_id: String in step.destination_scenes:
		assert_true(SceneCatalog.is_shipped(scene_id), scene_id)
		assert_false(scene_id.contains("res://"))


func test_a_foreign_map_destination_fails_validation() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("home")
	var step: StepDef = (def.steps[0] as StepDef).duplicate(true) as StepDef
	step.destination_scenes = PackedStringArray(["not_a_room"])
	def.steps = [step]
	assert_null(SceneDefLoader.validate(def))


func test_a_locked_door_refuses_and_points_at_care() -> void:
	var tpl: RefCounted = _mount_home_map()
	assert_true(bool(tpl.call("is_dimmed", "bath_door")))
	assert_eq(str(tpl.call("activate", "bath_door")), "")
	assert_eq(str(tpl.call("pointed_step")), "FEED")


func _mount_home_map() -> RefCounted:
	var def: SceneDef = SceneDefLoader.load_by_id("home")
	var step: StepDef = def.steps[0] as StepDef
	var tpl: RefCounted = TemplateCatalog.instantiate("t25_map")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.reactions = ReactionExecutor.new()
	tpl.call("setup", ctx)
	return tpl
