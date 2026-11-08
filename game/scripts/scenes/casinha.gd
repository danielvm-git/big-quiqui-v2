# story: e09s02
class_name CasinhaScene
extends Control
## Her own room (e09s02): drag a piece you own into the room and it stays where you let
## go. Positions are stored as ratios of the room, so the same room looks the same on a
## 16:9 desktop canvas and on the iPad's 4:3 canvas — no pixel is ever persisted.

const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/main_theme.ogg"
const VOICE_KEY: String = "vo.home.welcome"
const POP_SFX: String = "res://assets/audio/sfx/outfit_pop.ogg"

const STATE_EMPTY: String = "EMPTY"
const STATE_DRESSED: String = "DRESSED"
const LEGAL_EDGES: Dictionary = {STATE_EMPTY: [STATE_DRESSED], STATE_DRESSED: [STATE_EMPTY]}

## The tray teaches the verb; four pieces fit before the room itself is the list.
const TRAY_LIMIT: int = 4

var rig: QuiQuiRig = null
var hud: CoinTicketHud = null
var placement_area: Control = null
var tray: Control = null
var hint_layer: Control = null
var hint_manager: Node = null
var drag_hint: Node = null

var fsm: Fsm = null
var manual_step: bool = false

var _props: Dictionary = {}
var _normalized: Dictionary = {}
var _tray_ids: Array[String] = []
var _room_ids: Array[String] = []
var _hint_done: bool = false


func _ready() -> void:
	_bind_nodes()
	close_celebrate_if_needed()
	fsm = Fsm.new(STATE_EMPTY, LEGAL_EDGES, {})
	_setup_hints()
	_connect_inputs()
	_spawn_from_save()
	_refresh_state()
	AudioManager.play_voice_key(VOICE_KEY)
	_restore_music()
	_log("scene.ready", {"scene": "casinha"})
	call_deferred("layout_props")


func _bind_nodes() -> void:
	rig = get_node_or_null("QuiQuiRig") as QuiQuiRig
	hud = get_node_or_null("CoinTicketHud") as CoinTicketHud
	placement_area = get_node_or_null("PlacementArea") as Control
	tray = get_node_or_null("Tray") as Control
	hint_layer = get_node_or_null("HintLayer") as Control
	hint_manager = get_node_or_null("HintManager")
	drag_hint = get_node_or_null("HintLayer/DragHint")


func _setup_hints() -> void:
	if hint_manager != null and drag_hint != null:
		hint_manager.call("enqueue", drag_hint)


func _connect_inputs() -> void:
	var home: TapButton = get_node_or_null("HomeButton") as TapButton
	if home != null:
		home.tapped.connect(_on_home_tapped)
	if rig != null:
		rig.tapped.connect(_on_rig_tapped)
	if tray != null:
		tray.resized.connect(layout_props)
	# The room's own size settles one frame after the canvas does: a placement must
	# follow the room, never the rect that happened to be current when she dropped it.
	if placement_area != null:
		placement_area.resized.connect(layout_props)


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func advance(delta: float) -> void:
	if hint_manager != null and hint_manager.has_method("advance"):
		hint_manager.call("advance", maxf(delta, 0.0))


## Owned-but-unplaced pieces go to the tray; saved placements are restored at their
## ratio. Nothing owned means an empty room, which is a valid start, not an error.
func _spawn_from_save() -> void:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null:
		return
	var placed: Array[Dictionary] = progress.call("placed") as Array[Dictionary]
	for entry: Dictionary in placed:
		var id: String = str(entry.get("id", ""))
		if not bool(progress.call("owns_furniture", id)):
			continue
		var point: Vector2 = Vector2(float(entry.get("x", 0.5)), float(entry.get("y", 0.5)))
		_spawn(id, point)
	for id: String in _owned_list(progress):
		if _props.has(id) or _tray_ids.size() >= TRAY_LIMIT:
			continue
		_spawn(id, Vector2(-1.0, -1.0))


## (-1,-1) means "in the tray": a sentinel, not a coordinate, so a real 0..1 point is
## never confused with an unplaced piece.
func _spawn(id: String, point: Vector2) -> void:
	var item: FurnitureData = FurnitureCatalog.get_item(id)
	if item == null:
		return
	var prop: FurnitureProp = FurnitureProp.new()
	var placed: bool = point.x >= 0.0 and point.y >= 0.0
	_attach_spawn(id, point, prop, placed)
	prop.setup(item)
	prop.placement_area = placement_area
	prop.placed.connect(_on_prop_placed.bind(id))
	add_child(prop)
	_props[id] = prop
	if placed:
		_layout(prop)
		prop.visible = true


func _attach_spawn(id: String, point: Vector2, prop: FurnitureProp, placed: bool) -> void:
	if not placed:
		_tray_ids.append(id)
		var slot: int = _tray_ids.size() - 1
		prop.position = _tray_slot_origin(slot) - Vector2(FurnitureProp.PROP_SIZE, FurnitureProp.PROP_SIZE) * 0.5
	else:
		_room_ids.append(id)
		_normalized[id] = point


func _tray_slot_origin(slot: int) -> Vector2:
	var rect: Rect2 = tray.get_global_rect() if tray != null else Rect2(Vector2.ZERO, size)
	var columns: float = float(maxi(TRAY_LIMIT, 1))
	return Vector2(rect.position.x + rect.size.x * (float(slot) + 0.5) / columns, rect.position.y + rect.size.y * 0.5)


## Places a prop from its normalized coordinate. The ratio is authoritative: a resize
## moves the piece with the room instead of leaving it behind.
func _layout(prop: FurnitureProp) -> void:
	var id: String = prop.item_id
	var point: Vector2 = _normalized.get(id, Vector2(0.5, 0.5)) as Vector2
	var rect: Rect2 = placement_area.get_global_rect()
	var centre: Vector2 = rect.position + Vector2(point.x * rect.size.x, point.y * rect.size.y)
	prop.position = centre - prop.size * 0.5


func layout_props() -> void:
	var index: int = 0
	for id: String in _tray_ids:
		var prop: FurnitureProp = _props.get(id) as FurnitureProp
		if prop == null:
			continue
		prop.position = _tray_slot_origin(index) - prop.size * 0.5
		index += 1
	for id: String in _room_ids:
		var prop: FurnitureProp = _props.get(id) as FurnitureProp
		if prop != null:
			_layout(prop)


func _on_prop_placed(normalized: Vector2, id: String) -> void:
	place(id, normalized.x, normalized.y)


## Persists one placement (normalized), moves the piece off the tray and refreshes the
## room state. Returns false when `ProgressManager` refuses (unowned or invalid id).
func place(id: String, nx: float, ny: float) -> bool:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null or not bool(progress.call("place_furniture", id, nx, ny)):
		return false
	_normalized[id] = Vector2(clampf(nx, 0.0, 1.0), clampf(ny, 0.0, 1.0))
	_tray_ids.erase(id)
	if not _room_ids.has(id):
		_room_ids.append(id)
	var prop: FurnitureProp = _props.get(id) as FurnitureProp
	if prop != null:
		_layout(prop)
	_replenish_tray(progress)
	_stop_hint()
	_refresh_state()
	_play_stream("play_sfx", POP_SFX)
	_log("casinha.place", {"item": id})
	return true


func _replenish_tray(progress: Node) -> void:
	if progress == null or _tray_ids.size() >= TRAY_LIMIT:
		return
	for next_id: String in _owned_list(progress):
		if not _props.has(next_id) and _tray_ids.size() < TRAY_LIMIT:
			_spawn(next_id, Vector2(-1.0, -1.0))
			call_deferred("layout_props")


func _owned_list(progress: Node) -> Array[String]:
	var owned: Array[String] = []
	if progress != null and progress.has_method("owned_furniture"):
		var raw_owned: Variant = progress.call("owned_furniture")
		if raw_owned is Array:
			owned.assign(raw_owned)
	return owned


func tray_ids() -> Array[String]:
	return _tray_ids.duplicate()


func room_ids() -> Array[String]:
	return _room_ids.duplicate()


func _refresh_state() -> void:
	if fsm == null:
		return
	var want: String = STATE_DRESSED if not _room_ids.is_empty() else STATE_EMPTY
	if fsm.state != want:
		fsm.transition_to(want)


func _stop_hint() -> void:
	_hint_done = true
	if hint_manager != null:
		hint_manager.call("stop_current")
		hint_manager.call("begin_cooldown", 2.0)


func _maybe_start_hint() -> void:
	if _hint_done or hint_manager == null or drag_hint == null or placement_area == null:
		return
	if _tray_ids.is_empty():
		return
	if not bool(hint_manager.call("try_show_next")):
		return
	var first: FurnitureProp = _props.get(_tray_ids[0]) as FurnitureProp
	if first == null:
		return
	drag_hint.call("play", first.center(), placement_area.get_global_rect().get_center(), placement_area)


func close_celebrate_if_needed() -> void:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("close_celebrate_if_needed"):
		manager.call("close_celebrate_if_needed")


func _on_home_tapped() -> void:
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", CASA_PATH)


func _on_rig_tapped() -> void:
	if rig != null:
		rig.set_expression("laughing")


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		call_deferred("_maybe_start_hint")


func _restore_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		_log("audio.missing_art", {"track": "tema_principal"})
		return
	var manager: Node = get_node_or_null("/root/AudioManager")
	var stream: AudioStream = load(MUSIC_PATH) as AudioStream
	if manager == null or stream == null or bool(manager.call("is_music_playing", stream)):
		return
	manager.call("play_music", stream)
	_log("music.start", {"track": "tema_principal"})


func _play_stream(method: String, path: String) -> bool:
	var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
	if stream == null:
		_log("audio.missing_art", {"track": path.get_file().get_basename()})
		return false
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio == null:
		return false
	return bool(audio.call(method, stream))


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
