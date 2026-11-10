# story: e10s02
class_name PuzzlePiece
extends Control
## One quadrant piece of the magnetic jigsaw puzzle (e10s02). Wraps a TouchDraggable in
## SNAP_TO_SLOT mode. Slices the source texture into an AtlasTexture quadrant, and
## permanently parks in its matching slot upon drop.

signal locked(piece_id: int)

const SNAP_MARGIN: float = 32.0
const TRAY_OFFSETS: Array[Vector2] = [
	Vector2(0.0, 0.0),
	Vector2(210.0, 0.0),
	Vector2(420.0, 0.0),
	Vector2(630.0, 0.0),
]

var piece_id: int = -1
var draggable: TouchDraggable = null

var _locked: bool = false
var _slot: Control = null


static func apply_tray_layout(pieces: Array[PuzzlePiece], order: Array[int]) -> void:
	for slot_idx: int in range(order.size()):
		var piece_id: int = order[slot_idx]
		if piece_id < pieces.size() and slot_idx < TRAY_OFFSETS.size():
			var piece: PuzzlePiece = pieces[piece_id]
			if piece != null:
				piece.position = TRAY_OFFSETS[slot_idx]


static func quadrant_region(index: int, texture_size: Vector2) -> Rect2:
	var half_w: float = texture_size.x * 0.5
	var half_h: float = texture_size.y * 0.5
	var col: int = index % 2
	var row: int = index / 2
	return Rect2(float(col) * half_w, float(row) * half_h, half_w, half_h)


func setup_quadrant(art: Texture2D, region: Rect2, slot: Control) -> void:
	_slot = slot
	draggable = TouchDraggable.new()
	draggable.name = "Draggable_%d" % piece_id
	draggable.size = size
	draggable.mode = TouchDraggable.Mode.SNAP_TO_SLOT
	draggable.snap_target = slot
	draggable.snap_margin = SNAP_MARGIN
	draggable.payload_slot = str(piece_id)
	draggable.payload_id = str(piece_id)
	draggable.add_to_group("hit_target", true)
	draggable.add_child(_create_art(art, region))
	draggable.snapped.connect(_on_snapped)
	add_child(draggable)


func _create_art(art: Texture2D, region: Rect2) -> TextureRect:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = art
	atlas.region = region
	var rect: TextureRect = TextureRect.new()
	rect.name = "Art"
	rect.texture = atlas
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _on_snapped(slot_name: String, _id: String) -> void:
	if slot_name == str(piece_id):
		lock_in()


func is_locked() -> bool:
	return _locked


func lock_in() -> void:
	if _locked:
		return
	_locked = true
	if draggable != null:
		draggable.enabled = false
		if draggable.fsm != null and draggable.fsm.state == TouchDraggableStates.STATE_RETURNING:
			draggable.fsm.transition_to(TouchDraggableStates.STATE_REST)
		if _slot != null:
			draggable.global_position = _slot.global_position
	locked.emit(piece_id)


func unlock() -> void:
	_locked = false
	if draggable != null:
		draggable.enabled = true
		draggable.position = Vector2.ZERO
		if draggable.fsm != null:
			draggable.fsm.transition_to(TouchDraggableStates.STATE_REST)
