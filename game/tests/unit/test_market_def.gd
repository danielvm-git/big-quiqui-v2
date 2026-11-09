# story: e14s03
extends GutTest
## SC-e14s03-P0-01 — market buys through EconomyData once.


func before_each() -> void:
	TestReset.reset_all()


func test_market_def_loads_with_buy_mode() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("market")
	assert_not_null(def)
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t21_touch_each")
	assert_eq(step.mode, "buy")
	assert_eq(def.intro_voice_key, "vo.market.intro")


func test_a_short_wallet_does_not_buy() -> void:
	var tpl: RefCounted = _mount()
	var progress: Node = get_node("/root/ProgressManager")
	var writes: int = int(progress.get("write_count"))
	tpl.call("press", "mesa")
	assert_eq(int(progress.get("write_count")), writes, "SC-e14s03-P0-01 no save on refusal")


func _mount() -> RefCounted:
	var def: SceneDef = SceneDefLoader.load_by_id("market")
	var step: StepDef = def.steps[0] as StepDef
	var tray: Control = Control.new()
	tray.size = Vector2(1000.0, 160.0)
	add_child_autofree(tray)
	var tpl: RefCounted = TemplateCatalog.instantiate("t21_touch_each")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	tpl.call("setup", ctx)
	return tpl
