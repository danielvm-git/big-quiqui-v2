# story: e13s03
extends RefCounted
## Destinations from the def. Locks read the care loop. No wallet and no scene path.
## A hub: a child leaves through a door or through Home, so progress never claims the step.

const WISH_ART: Dictionary = {
	"FEED": "carrot",
	"BATH": "soap",
	"DRESS": "flower_tiara",
	"PLAY": "ball",
	"SLEEP": "zzz",
}
const DIM_ALPHA: float = 0.45

var _pan: PanPrimitive = PanPrimitive.new()
var _ctx: TemplateContext = null
var _open_steps: PackedStringArray = PackedStringArray()
var _refused: bool = false
var _pointed: String = ""
var _plays: int = 0
var _pad: MapPad = null
var _world: Control = null
var _pins: Dictionary = {}
var _wish: WishBubble = null
var _held_pin: String = ""


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_pan.world_size = _world_size()
	_pan.tolerance = _tolerance()
	_pan.view_size = _view_size()
	_open_steps = _care_open_steps()
	_build_surface()


func teardown() -> void:
	_hide_wish()
	for node: Node in [_pad, _world, _wish]:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_pad = null
	_world = null
	_wish = null
	_pins.clear()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return 0.0


func apply_view(size: Vector2) -> void:
	_pan.view_size = size


func set_open_steps(steps: PackedStringArray) -> void:
	_open_steps = steps
	_dim_locked()


func drag_by(delta: Vector2) -> void:
	_pan.drag_by(delta)
	_place_world()


func end_allows_tap() -> bool:
	return _pan.end_allows_tap()


func offset() -> Vector2:
	return _pan.offset


func follow(target: Vector2) -> void:
	_pan.follow(target)
	_place_world()


## Resolves a destination to a catalogue scene id, or "" with a soft refusal. Never a path.
func activate(dest_id: String) -> String:
	var index: int = _index_of(dest_id)
	if index < 0:
		return ""
	if _is_locked(index):
		_refuse()
		return ""
	_refused = false
	return _resolve(_scene_at(index))


## The tap path: resolve, then ask the scene manager to open the room.
func open_destination(dest_id: String) -> bool:
	var scene_id: String = activate(dest_id)
	if scene_id.is_empty():
		return false
	return SceneNav.open(TemplateKit.autoload("SceneManager"), scene_id)


func is_dimmed(dest_id: String) -> bool:
	var index: int = _index_of(dest_id)
	return index >= 0 and _is_locked(index)


func pointed_step() -> String:
	return _pointed


func refused() -> bool:
	return _refused


func play_count() -> int:
	return _plays


func pin_node(dest_id: String) -> Control:
	return _pins.get(dest_id) as Control


func reachable(dest_id: String) -> bool:
	var index: int = _index_of(dest_id)
	if index < 0:
		return false
	var at: Vector2 = _position_at(index)
	var box: Rect2 = Rect2(_pan.offset, _pan.view_size)
	return box.has_point(at) or box.has_point(at + Vector2(1.0, 1.0))


func _on_pressed(point: Vector2, index: int) -> void:
	_hide_wish()
	_open_steps = _care_open_steps()
	_dim_locked()
	var pin: String = _pin_at(point)
	if _pan.begin(point, index, not pin.is_empty()):
		_held_pin = pin


func _on_moved(point: Vector2, index: int) -> void:
	_pan.move_to(point, index)
	_place_world()


func _on_released(_point: Vector2, index: int) -> void:
	var held: String = _held_pin
	_held_pin = ""
	if _pan.end_allows_tap(index) and not held.is_empty():
		open_destination(held)


func _pin_at(point: Vector2) -> String:
	var world_point: Vector2 = point + _pan.offset
	for dest_id: String in _pins.keys():
		var index: int = _index_of(dest_id)
		if Rect2(_position_at(index), TapButton.MIN_HIT_SIZE).has_point(world_point):
			return dest_id
	return ""


func _build_surface() -> void:
	if _ctx == null or _ctx.step_def == null or not (_ctx.host is Control) or not _rows_match():
		return
	var host: Control = _ctx.host as Control
	_pad = MapPad.new()
	_pad.name = "MapPad"
	_world = Control.new()
	_world.name = "MapWorld"
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.size = _pan.world_size
	var slot: int = _under_chrome(host)
	host.add_child(_pad)
	host.add_child(_world)
	host.move_child(_pad, slot)
	host.move_child(_world, slot + 1)
	_pad.pressed.connect(_on_pressed)
	_pad.moved.connect(_on_moved)
	_pad.released.connect(_on_released)
	_build_pins()
	_place_world()


func _under_chrome(host: Control) -> int:
	var backdrop: Node = host.get_node_or_null("Background")
	return 0 if backdrop == null else backdrop.get_index() + 1


func _build_pins() -> void:
	var step: StepDef = _ctx.step_def
	for index: int in range(step.destination_ids.size()):
		var icon_id: String = step.destination_icons[index] if index < step.destination_icons.size() else ""
		var pin: TextureRect = ItemArt.icon(icon_id, TapButton.MIN_HIT_SIZE.x)
		pin.name = step.destination_ids[index]
		pin.set_anchors_preset(Control.PRESET_TOP_LEFT)
		pin.size = TapButton.MIN_HIT_SIZE
		pin.position = _position_at(index)
		pin.add_to_group("hit_target", true)
		_world.add_child(pin)
		_pins[step.destination_ids[index]] = pin
	_dim_locked()


func _dim_locked() -> void:
	for dest_id: String in _pins.keys():
		(_pins[dest_id] as Control).modulate.a = DIM_ALPHA if is_dimmed(dest_id) else 1.0


func _place_world() -> void:
	if _world != null and is_instance_valid(_world):
		_world.position = -_pan.offset


func _care_open_steps() -> PackedStringArray:
	var open: PackedStringArray = PackedStringArray()
	var loop: Node = TemplateKit.autoload("CareLoopManager")
	if loop == null or not loop.has_method("completed_steps"):
		return open
	for index: int in range(mini(int(loop.call("completed_steps")), CareSteps.ORDER.size())):
		open.append(CareSteps.ORDER[index])
	return open


func _world_size() -> Vector2:
	if _ctx == null or _ctx.step_def == null:
		return Vector2(1920.0, 1080.0)
	return _ctx.step_def.world_size


func _view_size() -> Vector2:
	if _ctx != null and _ctx.host is Control and (_ctx.host as Control).size.x > 0.0:
		return (_ctx.host as Control).size
	return Vector2(1920.0, 1080.0)


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
	if not _rows_match():
		return true
	var rule: String = _ctx.step_def.destination_locks[index]
	if rule.is_empty():
		return false
	return not _open_steps.has(rule)


func _rows_match() -> bool:
	var step: StepDef = _ctx.step_def
	var count: int = step.destination_ids.size()
	if step.destination_scenes.size() != count or step.destination_locks.size() != count:
		return false
	return step.destination_positions.size() == count


func _refuse() -> void:
	_refused = true
	_pointed = _next_care()
	_plays += 1
	_show_wish(_pointed)
	TemplateKit.play_miss(_ctx)


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


func _show_wish(care_step: String) -> void:
	if not WISH_ART.has(care_step) or not (_ctx.host is Control):
		return
	if _wish == null:
		_wish = WishBubble.new()
		_wish.name = "MapWish"
		(_ctx.host as Control).add_child(_wish)
	_wish.show_wish(ItemArt.path_for(str(WISH_ART[care_step])))


func _hide_wish() -> void:
	if _wish != null and is_instance_valid(_wish) and _wish.fsm != null:
		_wish.hide_wish()
