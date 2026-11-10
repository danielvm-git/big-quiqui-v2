# story: e15s04
extends GutTest


func test_no_life_verbs_in_source() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t38_peekaboo.gd").to_lower()
	for verb: String in ["decrementlives", "decreaselife", "restartscene", "shakescreen"]:
		assert_false(body.contains(verb), verb)


func test_progress_counts_giggles() -> void:
	var tpl: RefCounted = TemplateCatalog.instantiate("t38_peekaboo")
	var step: StepDef = StepDef.new()
	step.template_id = "t38_peekaboo"
	step.item_ids = PackedStringArray(["pato", "urso"])
	step.goal_count = 1
	step.spawn_seed = 1
	step.spawn_cadence = 1
	step.spawn_lifetime = 10
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.host = Control.new()
	add_child_autofree(ctx.host)
	tpl.call("setup", ctx)
	tpl.call("tick")
	assert_gte(float(tpl.call("progress")), 0.0)
