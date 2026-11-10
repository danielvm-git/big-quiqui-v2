# story: e13s04
extends GutTest
## SC-e13s04-P0-01, P2-01. Draw completes at the def threshold and residue still looks clean.


class HullStub:
	extends Control
	var hull: PackedVector2Array = PackedVector2Array()

	func scrub_hull_global() -> PackedVector2Array:
		return hull


func test_draw_completes_at_the_def_threshold() -> void:
	var tpl: RefCounted = _mount(0.9)
	_rub_cells(tpl, 14)
	assert_lt(float(tpl.call("progress")), 1.0, "14 of 16 is under 0.9")
	_rub_cells(tpl, 15)
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001, "SC-e13s04-P0-01")
	assert_lt(float(tpl.call("raw_coverage")), 1.0, "SC-e13s04-P2-01 residue")
	assert_true(bool(tpl.call("looks_clean")))


func test_templates_name_no_room() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t40_draw_fill.gd")
	assert_false(body.contains("bathroom"))
	assert_false(body.contains("foam"))


func _mount(threshold: float) -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t40_draw_fill"
	step.mode = "leave"
	step.completion_threshold = threshold
	var tpl: RefCounted = TemplateCatalog.instantiate("t40_draw_fill")
	var ctx: TemplateContext = _ctx(step)
	tpl.call("setup", ctx)
	tpl.call("begin_gesture")
	return tpl


func _ctx(step: StepDef) -> TemplateContext:
	var stub: HullStub = HullStub.new()
	stub.hull = _box()
	add_child_autofree(stub)
	var nodes: PlayerNodeTable = PlayerNodeTable.new()
	nodes.register("scrub_target", stub)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.nodes = nodes
	ctx.host = Node.new()
	add_child_autofree(ctx.host)
	return ctx


func _box() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, 0), Vector2(400, 0), Vector2(400, 400), Vector2(0, 400)])


func _rub_cells(tpl: RefCounted, limit: int) -> void:
	var filled: int = 0
	for col: int in range(4):
		for row: int in range(4):
			if filled >= limit:
				return
			tpl.call("note_rub", Vector2(50.0 + 100.0 * float(col), 50.0 + 100.0 * float(row)))
			filled += 1
