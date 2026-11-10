# story: e15s04
extends RefCounted
## Spawner friends; a tap giggles once per actor.

const TICK_SEC: float = 0.5

var _spawner: Spawner = Spawner.new()
var _tap: TapPrimitive = TapPrimitive.new()
var _ctx: TemplateContext = null
var _buttons: Dictionary = {}
var _clock: float = 0.0
var _giggles: int = 0
var _goal: int = 3


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_goal = maxi(ctx.step_def.goal_count, 1)
	_tap.mode = "count_n"
	_tap.goal = _goal
	_spawner.rng_seed = _int_of("spawn_seed", 9)
	_spawner.cadence = maxi(_int_of("spawn_cadence", 2), 1)
	_spawner.lifetime = maxi(_int_of("spawn_lifetime", 6), 1)
	_spawner.lane_count = 3
	_spawner.items = ctx.step_def.item_ids if ctx.step_def else PackedStringArray()
	_spawner.start()


func teardown() -> void:
	stop()


func advance(delta: float) -> void:
	_clock += maxf(delta, 0.0)
	while _clock >= TICK_SEC:
		_clock -= TICK_SEC
		tick()


func tick() -> void:
	_spawner.tick()
	_sync_actors()


func stop() -> void:
	_spawner.stop()
	for button: TapButton in _buttons.values():
		if is_instance_valid(button):
			button.queue_free()
	_buttons.clear()


func progress() -> float:
	return clampf(float(_giggles) / float(_goal), 0.0, 1.0)


func _sync_actors() -> void:
	var live: Array[String] = []
	for row: Dictionary in _spawner.live_rows():
		live.append(str(row.get("item", "")))
	for id: String in _buttons.keys():
		if not live.has(id):
			(_buttons[id] as TapButton).queue_free()
			_buttons.erase(id)
	for row: Dictionary in _spawner.live_rows():
		var friend_id: String = str(row.get("item", ""))
		if _buttons.has(friend_id):
			continue
		var lane: int = int(row.get("lane", 0))
		var button: TapButton = TemplateKit.tap_button(friend_id, Vector2(200.0 + 220.0 * float(lane), 280.0))
		button.tapped.connect(_on_giggle.bind(friend_id))
		if _ctx.host != null:
			(_ctx.host as Control).add_child(button)
		_buttons[friend_id] = button


func _on_giggle(friend_id: String) -> void:
	if not _buttons.has(friend_id):
		return
	_tap.note_tap(friend_id)
	_giggles += 1
	TemplateKit.play_hit(_ctx, "template.giggle", {"friend": friend_id})
	(_buttons[friend_id] as TapButton).queue_free()
	_buttons.erase(friend_id)
	if _ctx.runner != null:
		_ctx.runner.report_template_progress(progress())


func _int_of(field: String, fallback: int) -> int:
	if _ctx == null or _ctx.step_def == null:
		return fallback
	match field:
		"spawn_seed":
			return _ctx.step_def.spawn_seed if _ctx.step_def.spawn_seed != 0 else fallback
		"spawn_cadence":
			return _ctx.step_def.spawn_cadence if _ctx.step_def.spawn_cadence != 0 else fallback
		"spawn_lifetime":
			return _ctx.step_def.spawn_lifetime if _ctx.step_def.spawn_lifetime != 0 else fallback
	return fallback
