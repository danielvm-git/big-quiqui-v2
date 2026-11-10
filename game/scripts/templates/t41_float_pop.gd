# story: e16s01
extends RefCounted
## Floating spawns; tap pops one — no blade.

const TICK_SEC: float = 0.5

var _spawner: Spawner = Spawner.new()
var _tap: TapPrimitive = TapPrimitive.new()
var _ctx: TemplateContext = null
var _floats: Dictionary = {}
var _clock: float = 0.0
var _pops: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_tap.mode = "count_n"
	_tap.goal = maxi(ctx.step_def.goal_count, 1)
	_spawner.rng_seed = maxi(ctx.step_def.spawn_seed, 5)
	_spawner.cadence = maxi(ctx.step_def.spawn_cadence, 1)
	_spawner.lifetime = maxi(ctx.step_def.spawn_lifetime, 10)
	_spawner.lane_count = maxi(ctx.step_def.item_ids.size(), 1)
	_spawner.items = ctx.step_def.item_ids
	_spawner.start()


func teardown() -> void:
	_spawner.stop()
	for button: TapButton in _floats.values():
		if is_instance_valid(button):
			button.queue_free()
	_floats.clear()


func advance(delta: float) -> void:
	_clock += maxf(delta, 0.0)
	while _clock >= TICK_SEC:
		_clock -= TICK_SEC
		tick()


func tick() -> void:
	_spawner.tick()
	_sync()


func progress() -> float:
	return clampf(float(_pops) / float(_tap.goal), 0.0, 1.0)


func _sync() -> void:
	var live: Array[String] = []
	for row: Dictionary in _spawner.live_rows():
		live.append(_key(row))
	_drop_dead(live)
	for row: Dictionary in _spawner.live_rows():
		_place(row)


func _drop_dead(live: Array[String]) -> void:
	for key: String in _floats.keys():
		if live.has(key):
			continue
		(_floats[key] as TapButton).queue_free()
		_floats.erase(key)


func _place(row: Dictionary) -> void:
	var key: String = _key(row)
	var lane: int = int(row.get("lane", 0))
	var age: int = int(row.get("age", 0))
	var at: Vector2 = Vector2(180.0 * float(lane) + 80.0, 520.0 - float(age) * 18.0)
	if _floats.has(key):
		(_floats[key] as TapButton).position = at
		return
	var button: TapButton = TemplateKit.tap_button(str(row.get("item", "")), at)
	button.tapped.connect(_on_pop.bind(key))
	if _ctx.host != null:
		(_ctx.host as Control).add_child(button)
	_floats[key] = button


func _key(row: Dictionary) -> String:
	return "%s:%s" % [str(row.get("item", "")), str(row.get("born", 0))]


func _on_pop(key: String) -> void:
	if not _floats.has(key):
		return
	_tap.note_tap(key)
	_pops += 1
	TemplateKit.play_hit(_ctx, "template.pop", {"target": key})
	(_floats[key] as TapButton).queue_free()
	_floats.erase(key)
	if _ctx.runner != null:
		_ctx.runner.report_template_progress(progress())
