# story: e13s08
extends RefCounted
## Catch what spawns in the lane. A miss leaves quietly. Nothing is shot and nothing is lost.

const TICK_SEC: float = 0.6
const BASKET_ART: String = "bowl"

var _steer: SteerPrimitive = SteerPrimitive.new()
var _spawner: Spawner = Spawner.new()
var _ctx: TemplateContext = null
var _score: int = 0
var _clock: float = 0.0
var _pad: TouchPad = null
var _field: Control = null
var _basket: TextureRect = null
var _items: Dictionary = {}


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_steer.mode = "lanes"
	_steer.lane_count = _lanes()
	_steer.bounds = Rect2(Vector2.ZERO, _field_size())
	_spawner.rng_seed = _int_of("spawn_seed", 1)
	_spawner.cadence = maxi(_int_of("spawn_cadence", 2), 1)
	_spawner.lifetime = maxi(_int_of("spawn_lifetime", 4), 1)
	_spawner.lane_count = _lanes()
	_spawner.items = _item_ids()
	_spawner.start()
	_build_surface()


func teardown() -> void:
	stop()
	for node: Node in [_pad, _field]:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_pad = null
	_field = null
	_basket = null


func advance(delta: float) -> void:
	_clock += maxf(delta, 0.0)
	while _clock >= TICK_SEC:
		_clock -= TICK_SEC
		tick()


func tick() -> void:
	_spawner.tick()
	_sync_items()


## Test seam and keyboard-free shortcut: lift a finger over lane `index`.
func release_on_lane(index: int) -> void:
	_steer.begin(Vector2(_steer.lane_center(index), _steer.bounds.size.y * 0.8))
	_land(0)


func score() -> int:
	return _score


func misses() -> int:
	return _spawner.misses()


func first_lane() -> int:
	return _spawner.first_lane()


func live_count() -> int:
	return _spawner.live_count()


func item_node_count() -> int:
	return _items.size()


func basket_lane() -> int:
	return _steer.lane_index()


func stop() -> void:
	_spawner.stop()
	_sync_items()


func progress() -> float:
	return clampf(float(_score) / float(maxi(_int_of("goal_count", 3), 1)), 0.0, 1.0)


func _on_pressed(point: Vector2, index: int) -> void:
	_steer.begin(point, index)
	_move_basket()


func _on_moved(point: Vector2, index: int) -> void:
	_steer.move_to(point, index)
	_move_basket()


func _on_released(_point: Vector2, index: int) -> void:
	_land(index)


func _land(index: int) -> void:
	if not _steer.release(index):
		return
	var caught: int = _spawner.take_lane(_steer.lane_index())
	_move_basket()
	if caught > 0:
		_score += caught
		TemplateKit.play_hit(_ctx, "template.catch", {"count": caught})
	_sync_items()


func _build_surface() -> void:
	if _ctx == null or not (_ctx.host is Control):
		return
	var host: Control = _ctx.host as Control
	_pad = TouchPad.new()
	_pad.name = "LanePad"
	_field = Control.new()
	_field.name = "LaneField"
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field.set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop: Node = host.get_node_or_null("Background")
	var slot: int = 0 if backdrop == null else backdrop.get_index() + 1
	host.add_child(_pad)
	host.add_child(_field)
	host.move_child(_pad, slot)
	host.move_child(_field, slot + 1)
	_pad.pressed.connect(_on_pressed)
	_pad.moved.connect(_on_moved)
	_pad.released.connect(_on_released)
	_basket = ItemArt.icon(_basket_id(), TapButton.MIN_HIT_SIZE.x)
	_basket.name = "Basket"
	_basket.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_basket.size = TapButton.MIN_HIT_SIZE
	_field.add_child(_basket)
	_steer.position = Vector2(_steer.lane_center(0), _steer.bounds.size.y * 0.8)
	_move_basket()


func _move_basket() -> void:
	if _basket == null or not is_instance_valid(_basket):
		return
	var at: Vector2 = Vector2(_steer.position.x, _steer.bounds.size.y * 0.8)
	_basket.position = at - _basket.size * 0.5


## One picture per live row, freed when the row is caught, missed or stopped.
func _sync_items() -> void:
	var live: Dictionary = {}
	for row: Dictionary in _spawner.live_rows():
		var key: String = "%d:%d" % [int(row.get("born", 0)), int(row.get("lane", 0))]
		live[key] = row
		if not _items.has(key) and _field != null:
			_items[key] = _make_item(row)
		_place_item(key, row)
	for key: String in _items.keys():
		if not live.has(key):
			var gone: Node = _items[key] as Node
			if is_instance_valid(gone):
				gone.queue_free()
			_items.erase(key)


func _make_item(row: Dictionary) -> TextureRect:
	var item: TextureRect = ItemArt.icon(str(row.get("item", "")), 96.0)
	item.set_anchors_preset(Control.PRESET_TOP_LEFT)
	item.size = Vector2(96.0, 96.0)
	_field.add_child(item)
	return item


func _place_item(key: String, row: Dictionary) -> void:
	var item: Control = _items.get(key) as Control
	if item == null or not is_instance_valid(item):
		return
	var fall: float = clampf(float(row.get("age", 0)) / float(maxi(_spawner.lifetime, 1)), 0.0, 1.0)
	var lane_x: float = _steer.lane_center(int(row.get("lane", 0)))
	item.position = Vector2(lane_x - 48.0, fall * _steer.bounds.size.y * 0.8)


func _field_size() -> Vector2:
	if _ctx != null and _ctx.host is Control and (_ctx.host as Control).size.x > 0.0:
		return (_ctx.host as Control).size
	return Vector2(1920.0, 1080.0)


func _basket_id() -> String:
	if _ctx != null and _ctx.step_def != null and not _ctx.step_def.tool_id.is_empty():
		return _ctx.step_def.tool_id
	return BASKET_ART


func _lanes() -> int:
	return maxi(_int_of("lane_count", 3), 1)


func _int_of(field: String, fallback: int) -> int:
	if _ctx == null or _ctx.step_def == null:
		return fallback
	return int(_ctx.step_def.get(field))


func _item_ids() -> PackedStringArray:
	if _ctx == null or _ctx.step_def == null:
		return PackedStringArray()
	return _ctx.step_def.item_ids
