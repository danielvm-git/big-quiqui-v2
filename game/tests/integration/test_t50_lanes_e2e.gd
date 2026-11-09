# story: e13s08
extends GutTest
## SC-e13s08-P0-04. A long run leaves no spawned rows behind.


func test_stop_clears_every_spawn() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("penguin_probe")
	assert_not_null(def)
	var step: StepDef = def.steps[0] as StepDef
	var tpl: RefCounted = TemplateCatalog.instantiate(step.template_id)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	var host: Node = Node.new()
	add_child_autofree(host)
	ctx.host = host
	tpl.call("setup", ctx)
	for _i: int in range(40):
		tpl.call("tick")
	tpl.call("stop")
	assert_eq(int(tpl.call("live_count")), 0, "SC-e13s08-P0-04")
	assert_eq(host.get_child_count(), 0)
