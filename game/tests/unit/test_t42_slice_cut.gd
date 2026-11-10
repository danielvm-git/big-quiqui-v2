# story: e16s02
extends GutTest


func test_path_points_raise_coverage() -> void:
	var tpl: RefCounted = TemplateCatalog.instantiate("t42_slice_cut")
	var step: StepDef = StepDef.new()
	step.template_id = "t42_slice_cut"
	step.destination_positions = PackedVector2Array([Vector2(100.0, 100.0), Vector2(300.0, 100.0)])
	var tray: Control = Control.new()
	add_child_autofree(tray)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	ctx.host = Control.new()
	add_child_autofree(ctx.host)
	tpl.call("setup", ctx)
	tpl.call("note_point", Vector2(100, 100))
	assert_gt(float(tpl.call("progress")), 0.0)
