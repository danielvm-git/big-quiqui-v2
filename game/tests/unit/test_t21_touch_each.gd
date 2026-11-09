# story: e13s02
extends GutTest
## SC-e13s02-P1-03..04. A spent target still answers, and nothing ends the step on a timer.


func test_a_spent_target_replays_without_moving_progress() -> void:
	var tpl: RefCounted = _mount("any")
	tpl.call("press", "apple")
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001)
	tpl.call("press", "apple")
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001, "SC-e13s02-P1-03")
	assert_eq(int(tpl.call("play_count")), 2, "the second tap still answers")


func test_the_template_has_no_auto_end_timer() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t21_touch_each.gd")
	assert_false(body.contains("AddAutoEndTimer"), "SC-e13s02-P1-04")
	assert_false(body.contains("Timer"))
	assert_false(body.to_lower().contains("market"))


func test_probe_def_uses_the_template() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("touch_each_probe")
	assert_not_null(def)
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t21_touch_each")
	assert_eq(step.mode, "any")


func test_targets_meet_the_hit_floor() -> void:
	var tpl: RefCounted = _mount("count_n")
	var size: Vector2 = tpl.call("button_size", "apple")
	assert_gte(size.x, GeometryOracle.MIN_HIT_SIZE.x, "SC-e13s02-P2-01")
	assert_gte(size.y, GeometryOracle.MIN_HIT_SIZE.y)


func _mount(mode_name: String) -> RefCounted:
	var tray: Control = Control.new()
	add_child_autofree(tray)
	var step: StepDef = StepDef.new()
	step.template_id = "t21_touch_each"
	step.mode = mode_name
	step.repeat_count = 2
	step.item_ids = PackedStringArray(["apple", "grape"])
	step.on_hit_pose = "pleased"
	var tpl: RefCounted = TemplateCatalog.instantiate("t21_touch_each")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.tray = tray
	ctx.host = tray
	ctx.step_def = step
	ctx.reactions = ReactionExecutor.new()
	tpl.call("setup", ctx)
	return tpl
