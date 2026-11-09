# story: e13s04
extends GutTest
## SC-e13s04-P0-04. Soap, rinse and dry are three steps of one def.


func test_the_bathroom_def_names_three_templates() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("bathroom_probe")
	assert_not_null(def)
	assert_eq(def.steps.size(), 3)
	assert_eq((def.steps[0] as StepDef).template_id, "t40_draw_fill")
	assert_eq((def.steps[1] as StepDef).template_id, "t23_erase")
	assert_eq((def.steps[2] as StepDef).template_id, "t23_erase")


func test_each_step_reaches_done_under_touch() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("bathroom_probe")
	assert_not_null(def)
	for step: Resource in def.steps:
		var tpl: RefCounted = _play(step as StepDef)
		assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001, (step as StepDef).template_id)
		assert_eq(int(tpl.call("tray_taps")), 0, "SC-e13s04-P0-04 tray")


func _play(step: StepDef) -> RefCounted:
	var tpl: RefCounted = TemplateCatalog.instantiate(step.template_id)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.host = Node.new()
	add_child_autofree(ctx.host)
	var stub: Control = _hull()
	var nodes: PlayerNodeTable = PlayerNodeTable.new()
	nodes.register("scrub_target", stub)
	ctx.nodes = nodes
	tpl.call("setup", ctx)
	tpl.call("begin_gesture")
	_cover(tpl)
	var pad: Control = Control.new()
	pad.size = Vector2(80, 80)
	add_child_autofree(pad)
	for event: InputEvent in TouchSim.tap_events(pad, true):
		tpl.call("note_tray", event)
	return tpl


func _hull() -> Control:
	var stub: HullStub = HullStub.new()
	stub.hull = PackedVector2Array([Vector2(0, 0), Vector2(400, 0), Vector2(400, 400), Vector2(0, 400)])
	add_child_autofree(stub)
	return stub


func _cover(tpl: RefCounted) -> void:
	for col: int in range(4):
		for row: int in range(4):
			tpl.call("note_rub", Vector2(50.0 + 100.0 * float(col), 50.0 + 100.0 * float(row)))


class HullStub:
	extends Control
	var hull: PackedVector2Array = PackedVector2Array()

	func scrub_hull_global() -> PackedVector2Array:
		return hull
