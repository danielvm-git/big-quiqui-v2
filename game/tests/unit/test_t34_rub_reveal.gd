# story: e13s01
extends GutTest
## SC-e13s01-P1-01. Layers leave in def order and do not return.


func test_layers_reveal_in_order_and_never_return() -> void:
	var tpl: RefCounted = _mount()
	_rub_cells(tpl, 8)
	assert_gt(float(tpl.call("layer_alpha", 0)), 0.5, "A11 the first layer is still fading when the reveal starts")
	await wait_seconds(0.4)
	assert_almost_eq(tpl.call("layer_alpha", 0), 0.0, 0.001, "first layer leaves")
	assert_almost_eq(tpl.call("layer_alpha", 1), 1.0, 0.001, "second layer waits")
	_rub_cells(tpl, 16)
	await wait_seconds(0.4)
	assert_almost_eq(tpl.call("layer_alpha", 0), 0.0, 0.001)
	assert_almost_eq(tpl.call("layer_alpha", 1), 0.0, 0.001, "SC-e13s01-P1-01")
	_rub_cells(tpl, 16)
	assert_almost_eq(tpl.call("layer_alpha", 0), 0.0, 0.001, "reveal does not reverse")
	assert_almost_eq(tpl.call("layer_alpha", 1), 0.0, 0.001, "reveal does not reverse")


func test_probe_def_uses_the_template() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("rub_reveal_probe")
	assert_not_null(def, "catalogue probe until e14 assigns the room")
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t34_rub_reveal")
	assert_eq(step.item_ids.size(), 2)


func test_mouse_echo_does_not_double_count() -> void:
	var tpl: RefCounted = _mount()
	var tool: TouchDraggable = tpl.call("tool") as TouchDraggable
	assert_not_null(tool)
	_send(tool, _touch(Vector2(50.0, 50.0), true))
	_send(tool, _drag(Vector2(50.0, 50.0)))
	var echo: InputEventMouseMotion = InputEventMouseMotion.new()
	echo.device = -1
	echo.position = Vector2(150.0, 150.0)
	_send(tool, echo)
	assert_almost_eq(float(tpl.call("progress")), 1.0 / 16.0, 0.001, "SC-e13s01-P2-01")
	assert_gte(tool.size.x, GeometryOracle.MIN_HIT_SIZE.x)


func test_template_source_names_no_room() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t34_rub_reveal.gd")
	assert_false(body.to_lower().contains("playroom"))
	assert_false(body.to_lower().contains("kitchen"))
	assert_false(body.to_lower().contains("banheiro"))


func _mount() -> RefCounted:
	var tpl: RefCounted = TemplateCatalog.instantiate("t34_rub_reveal")
	tpl.call("setup", _ctx())
	tpl.call("begin_gesture")
	return tpl


func _ctx() -> TemplateContext:
	var host: Control = Control.new()
	var tray: Control = Control.new()
	add_child_autofree(host)
	add_child_autofree(tray)
	var nodes: PlayerNodeTable = PlayerNodeTable.new()
	nodes.register("scrub_target", _square())
	var ctx: TemplateContext = TemplateContext.new()
	ctx.host = host
	ctx.tray = tray
	ctx.nodes = nodes
	ctx.step_def = _step()
	ctx.reactions = ReactionExecutor.new()
	return ctx


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


func _send(control: Control, event: InputEvent) -> void:
	control._gui_input(TouchSim.gui_event(control, event))


func _touch(point: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	return event


func _drag(point: Vector2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.position = point
	return event


func _rub_cells(tpl: RefCounted, limit: int) -> void:
	var filled: int = 0
	for col: int in range(4):
		for row: int in range(4):
			if filled >= limit:
				return
			var point: Vector2 = Vector2(50.0 + 100.0 * float(col), 50.0 + 100.0 * float(row))
			tpl.call("note_rub", point)
			filled += 1
