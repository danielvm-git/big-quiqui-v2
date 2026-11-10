# story: e15s02
extends GutTest


func test_sequence_advances_in_order() -> void:
	var tpl: RefCounted = TemplateCatalog.instantiate("t55_find")
	var step: StepDef = StepDef.new()
	step.template_id = "t55_find"
	step.item_ids = PackedStringArray(["ball", "pinwheel", "plush"])
	var tray: Control = Control.new()
	add_child_autofree(tray)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	tpl.call("setup", ctx)
	assert_eq(tpl.call("active_id"), "ball")
	tpl.call("press", "plush")
	assert_eq(tpl.call("progress"), 0.0)
	tpl.call("press", "ball")
	assert_almost_eq(float(tpl.call("progress")), 1.0 / 3.0, 0.001)


func test_active_target_is_highlighted_on_screen() -> void:
	var tpl: RefCounted = TemplateCatalog.instantiate("t55_find")
	var step: StepDef = StepDef.new()
	step.template_id = "t55_find"
	step.item_ids = PackedStringArray(["ball", "pinwheel", "plush"])
	var tray: Control = Control.new()
	add_child_autofree(tray)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	tpl.call("setup", ctx)
	var ball: TapButton = tray.get_node("ball") as TapButton
	var plush: TapButton = tray.get_node("plush") as TapButton
	assert_not_null(ball.visual)
	assert_not_null(plush.visual)
	assert_ne(ball.visual.modulate, Color.WHITE)
	assert_eq(plush.visual.modulate, Color.WHITE)
