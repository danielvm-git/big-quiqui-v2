# story: e13s03
extends RefCounted
## Destinations from the def. Locks read the care loop. No wallet and no scene path.

var _pan: PanPrimitive = PanPrimitive.new()
var _ctx: TemplateContext = null
var _open_steps: PackedStringArray = PackedStringArray()
var _refused: bool = false
var _pointed: String = ""
var _plays: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_pan.world_size = _world()
	_pan.tolerance = _tolerance()
	_pan.view_size = Vector2(1920.0, 1080.0)


func apply_view(size: Vector2) -> void:
	_pan.view_size = size


func set_open_steps(steps: PackedStringArray) -> void:
	_open_steps = steps


func drag_by(delta: Vector2) -> void:
	_pan.drag_by(delta)


func begin(point: Vector2) -> void:
	_pan.begin(point)


func move_to(point: Vector2) -> void:
	_pan.move_to(point)


func end_allows_tap() -> bool:
	return _pan.end_allows_tap()


func offset() -> Vector2:
	return _pan.offset


func follow(target: Vector2) -> void:
	_pan.follow(target)


func activate(dest_id: String) -> String:
	var index: int = _index_of(dest_id)
	if index < 0:
		return ""
	if _is_locked(index):
		_refuse()
		return ""
	return _resolve(_scene_at(index))


func is_dimmed(dest_id: String) -> bool:
	var index: int = _index_of(dest_id)
	return index >= 0 and _is_locked(index)


func pointed_step() -> String:
	return _pointed


func refused() -> bool:
	return _refused


func play_count() -> int:
	return _plays


func reachable(dest_id: String) -> bool:
	var index: int = _index_of(dest_id)
	if index < 0:
		return false
	var at: Vector2 = _position_at(index)
	var box: Rect2 = Rect2(_pan.offset, _pan.view_size)
	return box.has_point(at) or box.has_point(at + Vector2(1.0, 1.0))


func _world() -> Vector2:
	if _ctx == null or _ctx.step_def == null:
		return Vector2(1920.0, 1080.0)
	return _ctx.step_def.world_size


func _tolerance() -> float:
	if _ctx == null or _ctx.step_def == null:
		return 24.0
	return _ctx.step_def.pan_tolerance


func _index_of(dest_id: String) -> int:
	if _ctx == null or _ctx.step_def == null:
		return -1
	return _ctx.step_def.destination_ids.find(dest_id)


func _scene_at(index: int) -> String:
	var scenes: PackedStringArray = _ctx.step_def.destination_scenes
	if index < 0 or index >= scenes.size():
		return ""
	return scenes[index]


func _position_at(index: int) -> Vector2:
	var points: PackedVector2Array = _ctx.step_def.destination_positions
	if index < 0 or index >= points.size():
		return Vector2.ZERO
	return points[index]


func _is_locked(index: int) -> bool:
	var locks: PackedStringArray = _ctx.step_def.destination_locks
	if index < 0 or index >= locks.size():
		return false
	var rule: String = locks[index]
	if rule.is_empty():
		return false
	return not _open_steps.has(rule)


func _refuse() -> void:
	_refused = true
	_pointed = _next_care()
	_plays += 1
	_play_soft()


func _next_care() -> String:
	for step_id: String in CareSteps.ORDER:
		if not _open_steps.has(step_id):
			return step_id
	return ""


func _resolve(scene_id: String) -> String:
	if not Ids.is_valid(scene_id) or not SceneCatalog.is_shipped(scene_id):
		LogSink.emit_to_diary("map.destination_rejected", {"reason": "unknown_scene"})
		return ""
	return scene_id


func _play_soft() -> void:
	if _ctx == null or _ctx.reactions == null:
		return
	var sfx: String = "sfx_soft_error"
	if _ctx.step_def != null and not _ctx.step_def.on_miss_sfx_id.is_empty():
		sfx = _ctx.step_def.on_miss_sfx_id
	_ctx.reactions.execute([{"kind": ReactionExecutor.KIND_SFX, "id": sfx}])
