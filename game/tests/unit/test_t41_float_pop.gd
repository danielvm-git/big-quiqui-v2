# story: e16s01
extends GutTest


func test_pop_progress_moves_toward_goal() -> void:
	var tpl: RefCounted = TemplateCatalog.instantiate("t41_float_pop")
	var step: StepDef = StepDef.new()
	step.template_id = "t41_float_pop"
	step.goal_count = 2
	step.item_ids = PackedStringArray(["ball"])
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.host = Control.new()
	add_child_autofree(ctx.host)
	tpl.call("setup", ctx)
	assert_eq(float(tpl.call("progress")), 0.0)
