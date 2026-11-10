# story: e16s01
extends GutTest


func test_collect_increments_progress() -> void:
	var tpl: RefCounted = TemplateCatalog.instantiate("t26_ride")
	var step: StepDef = StepDef.new()
	step.template_id = "t26_ride"
	step.goal_count = 2
	step.item_ids = PackedStringArray(["ball"])
	step.spawn_seed = 2
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.host = Control.new()
	add_child_autofree(ctx.host)
	tpl.call("setup", ctx)
	assert_eq(float(tpl.call("progress")), 0.0)
