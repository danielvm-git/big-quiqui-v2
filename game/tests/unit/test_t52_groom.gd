# story: e16s03
extends GutTest


func test_groom_starts_in_comb_phase() -> void:
	var tpl: RefCounted = TemplateCatalog.instantiate("t52_groom")
	var step: StepDef = StepDef.new()
	step.template_id = "t52_groom"
	var tray: Control = Control.new()
	add_child_autofree(tray)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	tpl.call("setup", ctx)
	assert_eq(float(tpl.call("progress")), 0.0)
