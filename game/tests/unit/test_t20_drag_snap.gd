# story: e12s06
extends GutTest
## SC-e12s06-P0-01..02, P1-01


func _template() -> RefCounted:
	return TemplateCatalog.instantiate("t20_drag_snap")


func test_repeat_three_completes_at_third_success() -> void:
	var runner: StepRunner = StepRunner.new()
	runner.manual_step = true
	var step: StepDef = StepDef.new()
	step.repeat_count = 3
	step.item_ids = PackedStringArray(["apple", "carrot", "grape"])
	step.receiver_id = "mouth"
	var mouth: Control = Control.new()
	mouth.size = Vector2(120.0, 120.0)
	var tray: Control = Control.new()
	add_child_autofree(tray)
	add_child_autofree(mouth)
	var nodes: PlayerNodeTable = PlayerNodeTable.new()
	nodes.register("mouth", mouth)
	var tpl: RefCounted = _template()
	var ctx: TemplateContext = TemplateContext.new()
	ctx.runner = runner
	ctx.tray = tray
	ctx.nodes = nodes
	ctx.step_def = step
	ctx.reactions = ReactionExecutor.new()
	tpl.call("setup", ctx)
	for item: TouchDraggable in tpl.call("active_draggables"):
		item.consumed.emit()
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001)


func test_miss_does_not_decrement_progress() -> void:
	var step: StepDef = StepDef.new()
	step.repeat_count = 3
	step.item_ids = PackedStringArray(["apple"])
	var tpl: RefCounted = _template()
	var tray: Control = Control.new()
	add_child_autofree(tray)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.tray = tray
	ctx.step_def = step
	ctx.reactions = ReactionExecutor.new()
	tpl.call("setup", ctx)
	for item: TouchDraggable in tpl.call("active_draggables"):
		item.drag_ended.emit()
	assert_almost_eq(float(tpl.call("progress")), 0.0, 0.001)


func test_template_source_has_no_kitchen_noun() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t20_drag_snap.gd")
	assert_false(body.to_lower().contains("kitchen"))
	assert_false(body.to_lower().contains("cozinha"))
