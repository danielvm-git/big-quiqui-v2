# story: e16s01
extends RefCounted
## Steer free inside bounds; overlap collects spawns.

const TICK_SEC: float = 0.4

var _steer: SteerPrimitive = SteerPrimitive.new()
var _spawner: Spawner = Spawner.new()
var _ctx: TemplateContext = null
var _pad: TouchPad = null
var _clock: float = 0.0
var _collected: int = 0
var _goal: int = 3


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_goal = maxi(ctx.step_def.goal_count, 1)
	_steer.mode = "free"
	_steer.bounds = Rect2(Vector2(80.0, 120.0), Vector2(760.0, 640.0))
	_spawner.rng_seed = maxi(ctx.step_def.spawn_seed, 3)
	_spawner.cadence = maxi(ctx.step_def.spawn_cadence, 2)
	_spawner.lifetime = maxi(ctx.step_def.spawn_lifetime, 8)
	_spawner.items = ctx.step_def.item_ids
	_spawner.start()
	_build_pad()


func teardown() -> void:
	_spawner.stop()
	if _pad != null and is_instance_valid(_pad):
		_pad.queue_free()
	_pad = null


func advance(delta: float) -> void:
	_clock += maxf(delta, 0.0)
	while _clock >= TICK_SEC:
		_clock -= TICK_SEC
		tick()


func tick() -> void:
	_spawner.tick()
	_collect_overlap()


func progress() -> float:
	return clampf(float(_collected) / float(_goal), 0.0, 1.0)


func _build_pad() -> void:
	if _ctx == null or _ctx.host == null:
		return
	_pad = TouchPad.new()
	_pad.name = "RidePad"
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pad.pressed.connect(_on_press)
	_pad.moved.connect(_on_drag)
	_pad.released.connect(_on_release)
	(_ctx.host as Control).add_child(_pad)


func _on_press(point: Vector2, index: int) -> void:
	_steer.begin(point, index)


func _on_drag(point: Vector2, index: int) -> void:
	_steer.move_to(point, index)


func _on_release(point: Vector2, index: int) -> void:
	_steer.release(index)


func _collect_overlap() -> void:
	var hero: Vector2 = _steer.position
	for row: Dictionary in _spawner.live_rows():
		var lane: int = int(row.get("lane", 0))
		var at: Vector2 = Vector2(200.0 * float(lane), 300.0)
		if hero.distance_to(at) < 100.0:
			_collected += 1
			_spawner.stop()
			_spawner.start()
			TemplateKit.play_hit(_ctx, "template.collect", {"count": _collected})
			if _ctx.runner != null:
				_ctx.runner.report_template_progress(progress())
			return
