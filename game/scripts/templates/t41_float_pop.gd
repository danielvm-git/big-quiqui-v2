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
	for row: Dictionary in _spawner.live_rows():
		var item_id: String = str(row.get("item", ""))
		var age: int = int(row.get("age", 0))
		if _floats.has(item_id):
			(_floats[item_id] as TapButton).position.y = 200.0 - float(age) * 12.0
			continue
		var button: TapButton = TemplateKit.tap_button(item_id, Vector2(320.0, 200.0))
		button.tapped.connect(_on_pop.bind(item_id))
		if _ctx.host != null:
			(_ctx.host as Control).add_child(button)
		_floats[item_id] = button


func _on_pop(item_id: String) -> void:
	if not _floats.has(item_id):
		return
	_tap.note_tap(item_id)
	_pops += 1
	TemplateKit.play_hit(_ctx, "template.pop", {"target": item_id})
	(_floats[item_id] as TapButton).queue_free()
	_floats.erase(item_id)
	if _ctx.runner != null:
		_ctx.runner.report_template_progress(progress())
