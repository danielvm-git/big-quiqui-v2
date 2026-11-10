# story: e16s02
extends RefCounted
## Rub along a def polyline — path coverage, no blade.

var _rub: RubPrimitive = RubPrimitive.new()
var _ctx: TemplateContext = null
var _path: PackedVector2Array = PackedVector2Array()
var _covered: int = 0
var _goal: int = 1
var _tool: TouchDraggable = null
var _hull: Control = null
var _done: bool = false


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_path = ctx.step_def.destination_positions if ctx.step_def else PackedVector2Array()
	_goal = maxi(_path.size(), 1)
	_rub.edge = 4
	_build_marks()
	_build_tool()


func teardown() -> void:
	if _tool != null and is_instance_valid(_tool):
		_tool.queue_free()
	if _hull != null and is_instance_valid(_hull):
		_hull.queue_free()
	_tool = null
	_hull = null
	_rub.release_all()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	if _done:
		return 1.0
	var ratio: float = float(_covered) / float(_goal)
	var need: float = 1.0
	if _ctx != null and _ctx.step_def != null and _ctx.step_def.completion_threshold > 0.0:
		need = _ctx.step_def.completion_threshold
	if ratio >= need:
		_done = true
		return 1.0
	return clampf(ratio / need, 0.0, 1.0)


func note_point(point: Vector2) -> void:
	if _done:
		return
	for index: int in range(_path.size()):
		if point.distance_to(_path[index]) < 48.0 and not _hit(index):
			_mark(index)
	if _covered >= _goal:
		_done = true
		TemplateKit.play_hit(_ctx, "template.slice", {"done": 1})
		if _ctx.runner != null:
			_ctx.runner.report_template_progress(1.0)


func _hit(index: int) -> bool:
	return _ctx != null and _ctx.host != null and (_ctx.host as Node).has_meta("slice_%d" % index)


func _mark(index: int) -> void:
	if _ctx.host == null:
		return
	(_ctx.host as Node).set_meta("slice_%d" % index, true)
	_covered += 1


func _build_tool() -> void:
	if _ctx == null or _ctx.tray == null:
		return
	_tool = TouchDraggable.new()
	_tool.name = "SliceTool"
	_tool.custom_minimum_size = TouchDraggable.MIN_HIT_SIZE
	_tool.size = TouchDraggable.MIN_HIT_SIZE
	_tool.mode = TouchDraggable.Mode.CONTINUOUS_SCRUB
	_tool.scrub_target = _hull
	_tool.scrubbed.connect(note_point)
	_tool.add_child(ItemArt.icon("sponge", TouchDraggable.MIN_HIT_SIZE.x))
	_ctx.tray.add_child(_tool)


func _build_marks() -> void:
	if _ctx == null or _ctx.host == null:
		return
	_hull = SliceHull.new()
	_hull.name = "SliceHull"
	_hull.polygon = _hull_polygon()
	_hull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(_ctx.host as Control).add_child(_hull)
	for point: Vector2 in _path:
		_dot(point)


func _dot(point: Vector2) -> void:
	var dot: ColorRect = ColorRect.new()
	dot.name = "SliceMark"
	dot.color = Color(0.95, 0.45, 0.2, 1.0)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.z_index = TemplateKit.LAYER_Z
	dot.size = Vector2(36.0, 36.0)
	dot.position = point - dot.size * 0.5
	(_ctx.host as Control).add_child(dot)


func _hull_polygon() -> PackedVector2Array:
	if _path.is_empty():
		return PackedVector2Array()
	var box: Rect2 = Rect2(_path[0], Vector2.ZERO)
	for point: Vector2 in _path:
		box = box.expand(point)
	box = box.grow(80.0)
	return PackedVector2Array(
		[box.position, box.position + Vector2(box.size.x, 0.0), box.end, box.position + Vector2(0.0, box.size.y)]
	)


class SliceHull:
	extends Control
	var polygon: PackedVector2Array = PackedVector2Array()

	func scrub_hull_global() -> PackedVector2Array:
		return polygon
