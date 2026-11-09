# story: e13s05
extends GutTest
## SC-e13s05-P1-03. The title screen has one interactive target.


func test_the_title_has_one_verb() -> void:
	var host: Control = Control.new()
	var decoration: ColorRect = ColorRect.new()
	decoration.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(decoration)
	add_child_autofree(host)
	var tpl: RefCounted = TemplateCatalog.instantiate("t0_title")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.host = host
	tpl.call("setup", ctx)
	assert_eq(int(tpl.call("interactive_count")), 1, "SC-e13s05-P1-03")
	assert_eq(decoration.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	tpl.call("press")
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001)
	var body: String = SourceScanner.text("res://scripts/templates/t0_title.gd")
	assert_false(body.contains("subscription"))
	assert_false(body.contains("policy"))
