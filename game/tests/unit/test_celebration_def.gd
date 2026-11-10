# story: e14s02
extends GutTest
## SC-e14s02-P0-04 — celebration pays once per cycle (reuses reward template tests).


func before_each() -> void:
	TestReset.reset_all()


func test_celebration_def_loads_as_reward_with_voice() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("celebration")
	assert_not_null(def)
	assert_eq((def.steps[0] as StepDef).template_id, "t32_reward")
	assert_eq(def.intro_voice_key, "vo.celebration.congrats")
	assert_eq(def.next_scene_id, "home")


func test_the_player_reward_pays_once_per_cycle() -> void:
	CareWalk.to_celebrate((Engine.get_main_loop() as SceneTree).root.get_node("CareLoopManager"))
	var def: SceneDef = SceneDefLoader.load_by_id("celebration")
	var tpl: RefCounted = _mount_reward(def)
	var before: int = int(get_node("/root/ProgressManager").call("get_coins"))
	assert_true(bool(tpl.call("collect")))
	assert_eq(int(get_node("/root/ProgressManager").call("get_coins")), before)
	assert_false(bool(tpl.call("collect")))


func _mount_reward(def: SceneDef) -> RefCounted:
	var step: StepDef = def.steps[0] as StepDef
	var tpl: RefCounted = TemplateCatalog.instantiate("t32_reward")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	return tpl
