# story: e16s01
extends RefCounted
## Tap a spawned mover once — no life counter and no screen rumble.

const TICK_SEC: float = 0.45

var _spawner: Spawner = Spawner.new()
var _tap: TapPrimitive = TapPrimitive.new()
var _ctx: TemplateContext = null
var _actors: Dictionary = {}
var _clock: float = 0.0
var _hits: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_tap.mode = "count_n"
	_tap.goal = maxi(ctx.step_def.goal_count, 1)
	_spawner.rng_seed = maxi(ctx.step_def.spawn_seed, 1)
	_spawner.cadence = maxi(ctx.step_def.spawn_cadence, 1)
	_spawner.lifetime = maxi(ctx.step_def.spawn_lifetime, 4)
	_spawner.items = ctx.step_def.item_ids
	_spawner.start()


func teardown() -> void:
	_spawner.stop()
	for button: TapButton in _actors.values():
		if is_instance_valid(button):
			button.queue_free()
	_actors.clear()


func advance(delta: float) -> void:
	_clock += maxf(delta, 0.0)
	while _clock >= TICK_SEC:
		_clock -= TICK_SEC
		tick()


func tick() -> void:
	_spawner.tick()
	_sync()


func progress() -> float:
	return clampf(float(_hits) / float(_tap.goal), 0.0, 1.0)


func _sync() -> void:
	var live: Array[String] = []
	for row: Dictionary in _spawner.live_rows():
		live.append(str(row.get("item", "")))
	for id: String in _actors.keys():
		if not live.has(id):
			(_actors[id] as TapButton).queue_free()
			_actors.erase(id)
	for row: Dictionary in _spawner.live_rows():
		var item_id: String = str(row.get("item", ""))
		if _actors.has(item_id):
			continue
		var lane: int = int(row.get("lane", 0))
		var button: TapButton = TemplateKit.tap_button(item_id, Vector2(180.0 * float(lane), 360.0))
		button.tapped.connect(_on_tap.bind(item_id))
		if _ctx.host != null:
			(_ctx.host as Control).add_child(button)
		_actors[item_id] = button


func _on_tap(item_id: String) -> void:
	if not _actors.has(item_id):
		return
	_tap.note_tap(item_id)
	_hits += 1
	TemplateKit.play_hit(_ctx, "template.tap", {"target": item_id})
	(_actors[item_id] as TapButton).queue_free()
	_actors.erase(item_id)
	if _ctx.runner != null:
		_ctx.runner.report_template_progress(progress())
