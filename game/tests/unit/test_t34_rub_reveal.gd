# story: e13s01
extends GutTest
## SC-e13s01-P1-01. Layers leave in def order and do not return.


func test_layers_reveal_in_order_and_never_return() -> void:
	var tpl: RefCounted = _mount()
	_rub_cells(tpl, 8)
	assert_almost_eq(tpl.call("layer_alpha", 0), 0.0, 0.001, "first layer leaves")
	assert_almost_eq(tpl.call("layer_alpha", 1), 1.0, 0.001, "second layer waits")
	_rub_cells(tpl, 16)
	assert_almost_eq(tpl.call("layer_alpha", 0), 0.0, 0.001)
	assert_almost_eq(tpl.call("layer_alpha", 1), 0.0, 0.001, "SC-e13s01-P1-01")
	_rub_cells(tpl, 16)
	assert_almost_eq(tpl.call("layer_alpha", 0), 0.0, 0.001, "reveal does not reverse")
	assert_almost_eq(tpl.call("layer_alpha", 1), 0.0, 0.001, "reveal does not reverse")


func test_template_source_names_no_room() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t34_rub_reveal.gd")
	assert_false(body.to_lower().contains("playroom"))
	assert_false(body.to_lower().contains("kitchen"))
	assert_false(body.to_lower().contains("banheiro"))


func _mount() -> RefCounted:
	var host: Control = Control.new()
	var tray: Control = Control.new()
	add_child_autofree(host)
	add_child_autofree(tray)
	var stub: Control = _square()
	var nodes: PlayerNodeTable = PlayerNodeTable.new()
	nodes.register("scrub_target", stub)
	var tpl: RefCounted = TemplateCatalog.instantiate("t34_rub_reveal")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.host = host
	ctx.tray = tray
	ctx.nodes = nodes
	ctx.step_def = _step()
	ctx.reactions = ReactionExecutor.new()
	tpl.call("setup", ctx)
	tpl.call("begin_gesture")
	return tpl


class HullStub:
	extends Control
	var hull: PackedVector2Array = PackedVector2Array()

	func scrub_hull_global() -> PackedVector2Array:
		return hull


func _step() -> StepDef:
	var step: StepDef = StepDef.new()
	step.template_id = "t34_rub_reveal"
	step.mode = "reveal"
	step.item_ids = PackedStringArray(["mud", "dust"])
	step.on_hit_pose = "pleased"
	return step


func _square() -> Control:
	var stub: HullStub = HullStub.new()
	stub.hull = _box()
	add_child_autofree(stub)
	return stub


func _box() -> PackedVector2Array:
	return PackedVector2Array(
		[
			Vector2(0, 0),
			Vector2(400, 0),
			Vector2(400, 400),
			Vector2(0, 400),
		]
	)


func _rub_cells(tpl: RefCounted, limit: int) -> void:
	var filled: int = 0
	for col: int in range(4):
		for row: int in range(4):
			if filled >= limit:
				return
			var point: Vector2 = Vector2(50.0 + 100.0 * float(col), 50.0 + 100.0 * float(row))
			tpl.call("note_rub", point)
			filled += 1
