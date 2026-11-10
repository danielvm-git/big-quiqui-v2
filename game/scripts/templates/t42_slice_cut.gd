# story: e16s02
extends RefCounted
## Rub along a def polyline — path coverage, no blade.

var _rub: RubPrimitive = RubPrimitive.new()
var _ctx: TemplateContext = null
var _path: PackedVector2Array = PackedVector2Array()
var _covered: int = 0
var _goal: int = 1
var _tool: TouchDraggable = null
var _done: bool = false


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_path = ctx.step_def.destination_positions if ctx.step_def else PackedVector2Array()
	_goal = maxi(_path.size(), 1)
	_rub.edge = 4
	_build_tool()


func teardown() -> void:
	if _tool != null and is_instance_valid(_tool):
		_tool.queue_free()
	_tool = null
	_rub.release_all()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	if _done:
		return 1.0
	return clampf(float(_covered) / float(_goal), 0.0, 1.0)


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
	_tool.scrubbed.connect(note_point)
	_tool.add_child(ItemArt.icon("sponge", TouchDraggable.MIN_HIT_SIZE.x))
	_ctx.tray.add_child(_tool)
