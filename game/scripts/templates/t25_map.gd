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
var _def: MapDef = MapDef.new()
var _open_steps: PackedStringArray = PackedStringArray()
var _refused: bool = false
var _pointed: String = ""
var _plays: int = 0
var _pad: TouchPad = null
var _world: Control = null
var _pins: Dictionary = {}
var _wish: WishBubble = null
var _held_pin: String = ""
var _rig_filter: int = -1


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_def = MapDef.new(ctx.step_def if ctx != null else null)
	_pan.world_size = _def.world_size()
	_pan.tolerance = _def.tolerance()
	_pan.view_size = _view_size()
	_open_steps = MapDef.open_steps_now()
	_rig_filter = TemplateKit.quiet_rig(ctx)
	_follow_first_open()
	_build_surface()
	_watch_resize()


func teardown() -> void:
	_hide_wish()
	TemplateKit.restore_rig(_ctx, _rig_filter)
	_unwatch_resize()
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


## Test seam: pretend the care loop opened these steps.
func set_open_steps(steps: PackedStringArray) -> void:
	_open_steps = steps
	_dim_locked()


## Test seam: a drag without a finger.
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
	var index: int = _def.index_of(dest_id)
	if index < 0:
		return ""
	if _def.is_locked(index, _open_steps):
		_refuse()
		return ""
	_refused = false
	return _resolve(_def.scene_at(index))


## The tap path: resolve, then ask the scene manager to open the room.
func open_destination(dest_id: String) -> bool:
	var scene_id: String = activate(dest_id)
	if scene_id.is_empty():
		return false
	return SceneNav.open(TemplateKit.autoload("SceneManager"), scene_id)


func is_dimmed(dest_id: String) -> bool:
	var index: int = _def.index_of(dest_id)
	return index >= 0 and _def.is_locked(index, _open_steps)


func pointed_step() -> String:
	return _pointed


func refused() -> bool:
	return _refused


func play_count() -> int:
	return _plays


func pin_node(dest_id: String) -> Control:
	return _pins.get(dest_id) as Control


func reachable(dest_id: String) -> bool:
	var index: int = _def.index_of(dest_id)
	if index < 0:
		return false
	var at: Vector2 = _def.position_at(index)
	var box: Rect2 = Rect2(_pan.offset, _pan.view_size)
	return box.has_point(at) or box.has_point(at + Vector2(1.0, 1.0))


func _on_pressed(point: Vector2, index: int) -> void:
	_hide_wish()
	_open_steps = MapDef.open_steps_now()
	_dim_locked()
	var pin: String = _pin_at(point)
	if _pan.begin(point, index, not pin.is_empty()):
		_held_pin = pin


func _on_moved(point: Vector2, index: int) -> void:
	_pan.move_to(point, index)
	_place_world()


func _on_released(_point: Vector2, index: int) -> void:
	if not _pan.owns(index):
		return
	var held: String = _held_pin
	_held_pin = ""
	if _pan.end_allows_tap(index) and not held.is_empty():
		open_destination(held)


func _pin_at(point: Vector2) -> String:
	var world_point: Vector2 = point + _pan.offset
	for dest_id: String in _pins.keys():
		var index: int = _def.index_of(dest_id)
		if Rect2(_def.position_at(index), TapButton.MIN_HIT_SIZE).has_point(world_point):
			return dest_id
	return ""


func _build_surface() -> void:
	if _ctx == null or _ctx.step_def == null or not (_ctx.host is Control) or not _def.rows_match():
		return
	_pad = TouchPad.new()
	_pad.name = "MapPad"
	_world = Control.new()
	_world.name = "MapWorld"
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.size = _pan.world_size
	TemplateKit.mount_pad(_ctx.host as Control, _pad, _world, [_on_pressed, _on_moved, _on_released])
	_build_pins()
	_place_world()


func _build_pins() -> void:
	var step: StepDef = _ctx.step_def
	for index: int in range(step.destination_ids.size()):
		var icon_id: String = _def.icon_at(index)
		var pin: TextureRect = ItemArt.icon(icon_id, TapButton.MIN_HIT_SIZE.x)
		pin.name = step.destination_ids[index]
		pin.set_anchors_preset(Control.PRESET_TOP_LEFT)
		pin.size = TapButton.MIN_HIT_SIZE
		pin.position = _def.position_at(index)
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


## The room opens on the first door that is open, so the child sees where to go.
func _follow_first_open() -> void:
	for index: int in range(_def.count()):
		if not _def.is_locked(index, _open_steps):
			_pan.follow(_def.position_at(index) + TapButton.MIN_HIT_SIZE * 0.5)
			return


func _watch_resize() -> void:
	if _ctx != null and _ctx.host is Control and not (_ctx.host as Control).resized.is_connected(_on_resized):
		(_ctx.host as Control).resized.connect(_on_resized)


func _unwatch_resize() -> void:
	if _ctx != null and _ctx.host is Control and (_ctx.host as Control).resized.is_connected(_on_resized):
		(_ctx.host as Control).resized.disconnect(_on_resized)


## A rotation or a new canvas changes how much world fits, so the clamp is read again.
func _on_resized() -> void:
	apply_view(_view_size())
	_pan.drag_by(Vector2.ZERO)
	_place_world()


func _view_size() -> Vector2:
	if _ctx != null and _ctx.host is Control and (_ctx.host as Control).size.x > 0.0:
		return (_ctx.host as Control).size
	return Vector2(1920.0, 1080.0)


func _refuse() -> void:
	_refused = true
	_pointed = MapDef.next_care(_open_steps)
	_plays += 1
	_show_wish(_pointed)
	TemplateKit.play_miss(_ctx)


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
