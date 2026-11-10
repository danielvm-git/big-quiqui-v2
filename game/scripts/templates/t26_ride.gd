# story: e16s01
extends RefCounted
## Steer a rider onto spawned toys. The toys and the rider are pictures inside the pad.

const TICK_SEC: float = 0.4
const HIT: float = 90.0

var _steer: SteerPrimitive = SteerPrimitive.new()
var _spawner: Spawner = Spawner.new()
var _ctx: TemplateContext = null
var _pad: TouchPad = null
var _hero: TextureRect = null
var _toys: Dictionary = {}
var _clock: float = 0.0
var _collected: int = 0
var _goal: int = 3


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_goal = maxi(ctx.step_def.goal_count, 1)
	_steer.mode = "free"
	_steer.bounds = Rect2(Vector2(80.0, 160.0), Vector2(900.0, 640.0))
	_steer.position = _steer.bounds.get_center()
	_arm_spawner(ctx)
	_build_pad()
	_build_hero()


func teardown() -> void:
	_spawner.stop()
	_free_node(_pad)
	_free_node(_hero)
	for node: Node in _toys.values():
		_free_node(node)
	_toys.clear()
	_pad = null
	_hero = null


func advance(delta: float) -> void:
	_clock += maxf(delta, 0.0)
	while _clock >= TICK_SEC:
		_clock -= TICK_SEC
		tick()


func tick() -> void:
	_spawner.tick()
	_sync_toys()
	_collect_overlap()
	_place_hero()


func progress() -> float:
	return clampf(float(_collected) / float(_goal), 0.0, 1.0)


func _arm_spawner(ctx: TemplateContext) -> void:
	_spawner.rng_seed = maxi(ctx.step_def.spawn_seed, 3)
	_spawner.cadence = maxi(ctx.step_def.spawn_cadence, 2)
	_spawner.lifetime = maxi(ctx.step_def.spawn_lifetime, 8)
	_spawner.lane_count = maxi(ctx.step_def.item_ids.size(), 2)
	_spawner.items = ctx.step_def.item_ids
	_spawner.start()


func _build_pad() -> void:
	if _ctx == null or _ctx.host == null:
		return
	_pad = TouchPad.new()
	_pad.name = "RidePad"
	_pad.z_index = TemplateKit.SURFACE_Z
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pad.pressed.connect(_on_press)
	_pad.moved.connect(_on_drag)
	_pad.released.connect(_on_release)
	(_ctx.host as Control).add_child(_pad)


func _build_hero() -> void:
	if _ctx == null or _ctx.host == null:
		return
	_hero = _picture("star")
	_hero.name = "RideHero"
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.z_index = TemplateKit.SURFACE_Z + 1
	(_ctx.host as Control).add_child(_hero)
	_place_hero()


func _on_press(point: Vector2, index: int) -> void:
	_steer.begin(point, index)
	_place_hero()


func _on_drag(point: Vector2, index: int) -> void:
	_steer.move_to(point, index)
	_place_hero()
	_collect_overlap()


func _on_release(point: Vector2, index: int) -> void:
	_steer.move_to(point, index)
	_steer.release(index)
	_place_hero()


func _place_hero() -> void:
	if _hero == null:
		return
	_hero.position = _steer.position - _hero.size * 0.5


func _sync_toys() -> void:
	var live: Array[String] = []
	for row: Dictionary in _spawner.live_rows():
		live.append(_row_key(row))
	_drop_stale(live)
	for row: Dictionary in _spawner.live_rows():
		_ensure_toy(row)


func _drop_stale(live: Array[String]) -> void:
	for key: String in _toys.keys():
		if live.has(key):
			continue
		_free_node(_toys[key] as Node)
		_toys.erase(key)


func _ensure_toy(row: Dictionary) -> void:
	var key: String = _row_key(row)
	var spot: Vector2 = _spot(int(row.get("lane", 0)), int(row.get("age", 0)))
	if _toys.has(key):
		(_toys[key] as TextureRect).position = spot
		return
	var art: TextureRect = _picture(str(row.get("item", "ball")))
	art.name = "RideItem"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.z_index = TemplateKit.SURFACE_Z
	if _ctx.host != null:
		(_ctx.host as Control).add_child(art)
	art.position = spot
	_toys[key] = art


func _spot(lane: int, age: int) -> Vector2:
	var lanes: int = maxi(_spawner.lane_count, 1)
	var span: float = _steer.bounds.size.x / float(lanes)
	var x: float = _steer.bounds.position.x + span * (float(lane) + 0.5)
	var y: float = _steer.bounds.position.y + 80.0 + float(age) * 36.0
	return Vector2(x, y)


func _collect_overlap() -> void:
	for key: String in _toys.keys():
		var toy: TextureRect = _toys[key] as TextureRect
		if toy == null or _steer.position.distance_to(toy.position + toy.size * 0.5) > HIT:
			continue
		_collect(key)
		return


func _collect(key: String) -> void:
	_collected += 1
	_free_node(_toys[key] as Node)
	_toys.erase(key)
	_spawner.stop()
	_spawner.start()
	TemplateKit.play_hit(_ctx, "template.collect", {"count": _collected})
	if _ctx.runner != null:
		_ctx.runner.report_template_progress(progress())


func _picture(art_id: String) -> TextureRect:
	var art: TextureRect = ItemArt.icon(art_id, 120.0)
	art.set_anchors_preset(Control.PRESET_TOP_LEFT)
	art.size = Vector2(120.0, 120.0)
	return art


func _row_key(row: Dictionary) -> String:
	return "%s:%s" % [str(row.get("item", "")), str(row.get("born", 0))]


func _free_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()
