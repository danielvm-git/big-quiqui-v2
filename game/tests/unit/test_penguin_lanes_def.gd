# story: e14s04
extends GutTest
## SC-e14s04-P0-02 — penguin lanes def loads and stays playable past a miss.


func before_each() -> void:
	TestReset.reset_all()


func test_penguin_lanes_def_loads() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("penguin_lanes")
	assert_not_null(def)
	assert_eq(def.intro_voice_key, "vo.penguin.intro")
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t50_lanes")
	assert_eq(step.goal_count, 3)


func test_a_miss_does_not_end_the_round() -> void:
	var tpl: RefCounted = _mount()
	tpl.call("tick")
	var lane: int = int(tpl.call("first_lane"))
	tpl.call("release_on_lane", (lane + 1) % 3)
	for _i: int in range(6):
		tpl.call("tick")
	assert_gt(int(tpl.call("misses")), 0)
	assert_lt(float(tpl.call("progress")), 1.0, "SC-e14s04-P0-02 still playable")


func _mount() -> RefCounted:
	var def: SceneDef = SceneDefLoader.load_by_id("penguin_lanes")
	var step: StepDef = def.steps[0] as StepDef
	var tpl: RefCounted = TemplateCatalog.instantiate("t50_lanes")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	return tpl
