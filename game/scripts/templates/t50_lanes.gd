# story: e13s08
extends RefCounted
## Catch what spawns in the lane. A miss leaves quietly. Nothing is shot.

var _steer: SteerPrimitive = SteerPrimitive.new()
var _spawner: Spawner = Spawner.new()
var _ctx: TemplateContext = null
var _score: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_steer.mode = "lanes"
	_steer.lane_count = _lanes()
	_steer.bounds = Rect2(0.0, 0.0, 1920.0, 1080.0)
	_spawner.seed = _seed()
	_spawner.cadence = _cadence()
	_spawner.lifetime = _lifetime()
	_spawner.lane_count = _lanes()
	_spawner.items = _items()
	_spawner.start()


func tick() -> void:
	_spawner.tick()


func release_on_lane(index: int) -> void:
	var point: Vector2 = Vector2(_steer.lane_center(index), 40.0)
	_steer.begin(point)
	_steer.release()
	_score += _spawner.take_lane(_steer.lane_index())


func note_event(event: InputEvent) -> void:
	if event is InputEventMouse and event.device == -1:
		return
	if event is InputEventScreenDrag:
		_steer.move_to(event.position)


func score() -> int:
	return _score


func misses() -> int:
	return _spawner.miss_count


func first_lane() -> int:
	return _spawner.first_lane()


func live_count() -> int:
	return _spawner.live_count()


func stop() -> void:
	_spawner.stop()


func progress() -> float:
	return clampf(float(_score) / float(maxi(_goal(), 1)), 0.0, 1.0)


func claims_completion() -> bool:
	return false


func _lanes() -> int:
	if _ctx == null or _ctx.step_def == null:
		return 3
	return maxi(_ctx.step_def.lane_count, 1)


func _seed() -> int:
	if _ctx == null or _ctx.step_def == null:
		return 1
	return _ctx.step_def.spawn_seed


func _cadence() -> int:
	if _ctx == null or _ctx.step_def == null:
		return 2
	return maxi(_ctx.step_def.spawn_cadence, 1)


func _lifetime() -> int:
	if _ctx == null or _ctx.step_def == null:
		return 4
	return maxi(_ctx.step_def.spawn_lifetime, 1)


func _goal() -> int:
	if _ctx == null or _ctx.step_def == null:
		return 3
	return maxi(_ctx.step_def.goal_count, 1)


func _items() -> PackedStringArray:
	if _ctx == null or _ctx.step_def == null:
		return PackedStringArray()
	return _ctx.step_def.item_ids
