# story: e16s02
extends GutTest


func test_hidden_cup_is_among_ids() -> void:
	var tpl: RefCounted = TemplateCatalog.instantiate("t46_cups")
	var step: StepDef = StepDef.new()
	step.template_id = "t46_cups"
	step.spawn_seed = 2
	step.item_ids = PackedStringArray(["cup_a", "cup_b", "cup_c"])
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.host = Control.new()
	add_child_autofree(ctx.host)
	tpl.call("setup", ctx)
	assert_true(step.item_ids.has(tpl.call("hidden_under")))
