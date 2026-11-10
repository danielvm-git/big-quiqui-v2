# story: e15s01
extends GutTest


class HullStub:
	extends Control
	var hull: PackedVector2Array = PackedVector2Array()

	func scrub_hull_global() -> PackedVector2Array:
		return hull


func test_paint_selects_color_and_completes_at_threshold() -> void:
	var tpl: RefCounted = TemplateCatalog.instantiate("t44_paint")
	var step: StepDef = StepDef.new()
	step.template_id = "t44_paint"
	step.item_ids = PackedStringArray(["paint_red", "paint_blue"])
	step.slot_ids = PackedStringArray(["scrub_target"])
	step.completion_threshold = 0.5
	var stub: HullStub = HullStub.new()
	stub.hull = PackedVector2Array([Vector2(0, 0), Vector2(400, 0), Vector2(400, 400), Vector2(0, 400)])
	stub.size = Vector2(400, 400)
	add_child_autofree(stub)
	var nodes: PlayerNodeTable = PlayerNodeTable.new()
	nodes.register("scrub_target", stub)
	var tray: Control = Control.new()
	add_child_autofree(tray)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	ctx.nodes = nodes
	ctx.host = Control.new()
	add_child_autofree(ctx.host)
	tpl.call("setup", ctx)
	tpl.call("select_color", "paint_blue")
	assert_eq(tpl.call("active_color"), "paint_blue")
	_rub_grid(tpl)
	assert_gte(float(tpl.call("progress")), 0.5)


func _rub_grid(tpl: RefCounted) -> void:
	tpl.call("begin_gesture")
	var filled: int = 0
	for col: int in range(4):
		for row: int in range(4):
			if filled >= 8:
				break
			tpl.call("note_rub", Vector2(50.0 + 100.0 * float(col), 50.0 + 100.0 * float(row)))
			filled += 1
	tpl.call("end_gesture")
	tpl.call("advance", 0.0)


func test_template_source_has_no_room_noun() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t44_paint.gd")
	assert_false(body.to_lower().contains("coloring"))
