# story: e13s01
# story: e13s04
extends GutTest
## Review round 2 (A9). `clear`, `leave` and `reveal` are data the def names, and the grid edge is data too.


class HullStub:
	extends Control
	var hull: PackedVector2Array = PackedVector2Array()

	func scrub_hull_global() -> PackedVector2Array:
		return hull


func test_the_def_mode_overrides_the_template_default() -> void:
	var surface: RubSurface = _surface("leave", "clear", 0)
	assert_eq(surface.mode, "leave", "the def names leave and the template default was clear")
	assert_eq(_surface("single", "clear", 0).mode, "clear", "the unset default falls back to the template")
	assert_eq(_surface("teleport", "leave", 0).mode, "leave", "an unknown word falls back too")


func test_a_leave_rub_fills_the_layer_and_a_clear_rub_empties_it() -> void:
	var leave: CleaningRub = _cleaning("leave", "clear")
	_rub(leave, 8)
	assert_almost_eq(leave.layer_alpha(), 0.5, 0.05, "leave: half the area, half the layer")
	var clear: CleaningRub = _cleaning("clear", "leave")
	_rub(clear, 8)
	assert_almost_eq(clear.layer_alpha(), 0.5, 0.05, "clear: half the area, half the layer is gone")


func test_the_grid_edge_comes_from_the_def_and_a_wild_value_falls_back() -> void:
	assert_eq(_surface("single", "clear", 2).rub.edge, 2)
	assert_eq(_surface("single", "clear", 0).rub.edge, RubPrimitive.CELL_EDGE)
	assert_eq(_surface("single", "clear", 500).rub.edge, RubPrimitive.CELL_EDGE)


func test_a_leave_layer_stays_for_the_next_step_and_a_clear_layer_does_not() -> void:
	var kept: CleaningRub = _cleaning("leave", "clear")
	_rub(kept, 8)
	var ctx: TemplateContext = kept.get("_ctx")
	kept.teardown()
	assert_not_null(ctx.nodes.resolve("foam_large"), "the soap is still there")
	var gone: CleaningRub = _cleaning("clear", "clear")
	var layer: Control = gone.get("_surface").layers[0]
	gone.teardown()
	await wait_process_frames(1)
	assert_false(is_instance_valid(layer), "an erased layer leaves with its step")


func _ctx(mode: String, grid: int) -> TemplateContext:
	var host: Control = Control.new()
	add_child_autofree(host)
	var stub: HullStub = HullStub.new()
	stub.hull = PackedVector2Array([Vector2(0, 0), Vector2(400, 0), Vector2(400, 400), Vector2(0, 400)])
	stub.size = Vector2(400.0, 400.0)
	host.add_child(stub)
	var step: StepDef = StepDef.new()
	step.mode = mode
	step.param_int = grid
	step.completion_threshold = 1.0
	step.item_ids = PackedStringArray(["foam_large"])
	var ctx: TemplateContext = TemplateContext.new()
	ctx.host = host
	ctx.nodes = PlayerNodeTable.new()
	ctx.nodes.register("scrub_target", stub)
	ctx.step_def = step
	return ctx


func _surface(mode: String, default_mode: String, grid: int) -> RubSurface:
	var surface: RubSurface = RubSurface.new()
	surface.bind(_ctx(mode, grid), Callable(), default_mode)
	return surface


func _cleaning(mode: String, default_mode: String) -> CleaningRub:
	var clean: CleaningRub = CleaningRub.new()
	clean.bind(_ctx(mode, 0), default_mode)
	clean.begin_gesture()
	return clean


func _rub(clean: CleaningRub, cells: int) -> void:
	var filled: int = 0
	for col: int in range(4):
		for row: int in range(4):
			if filled < cells:
				clean.note_rub(Vector2(50.0 + 100.0 * float(col), 50.0 + 100.0 * float(row)))
				filled += 1
