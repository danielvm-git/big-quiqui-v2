# story: e08s02
class_name DragHint
extends Control
## Ghost hand sliding from bag to bin (FIX-02). MOUSE_FILTER_IGNORE — teaching only.

const DURATION_SEC: float = 0.85

var manual_step: bool = false

var _hand: Control = null
var _from_global: Vector2 = Vector2.ZERO
var _to_global: Vector2 = Vector2.ZERO
var _target_visual: Control = null
var _elapsed: float = 0.0
var _playing: bool = false
var _base_target_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	_hand = ColorRect.new()
	_hand.name = "Hand"
	_hand.custom_minimum_size = Vector2(72.0, 96.0)
	_hand.color = Color(1.0, 0.62, 0.74, 0.92)
	_hand.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_hand)


func play(from_global: Vector2, to_global: Vector2, target_pulse: Control = null) -> void:
	_from_global = from_global
	_to_global = to_global
	_target_visual = target_pulse
	if _target_visual != null:
		_base_target_scale = _target_visual.scale
	_elapsed = 0.0
	_playing = true
	visible = true
	_place_hand(_from_global)


func stop() -> void:
	_playing = false
	_elapsed = 0.0
	if _target_visual != null and is_instance_valid(_target_visual):
		_target_visual.scale = _base_target_scale
	visible = false


func done() -> bool:
	return not _playing


func advance(delta: float) -> void:
	if manual_step:
		return
	if not _playing:
		return
	_elapsed += maxf(delta, 0.0)
	var t: float = 1.0 if DURATION_SEC <= 0.0 else clampf(_elapsed / DURATION_SEC, 0.0, 1.0)
	var pos: Vector2 = _from_global.lerp(_to_global, t)
	_place_hand(pos)
	if _target_visual != null and is_instance_valid(_target_visual):
		var pulse: float = 1.0 + 0.08 * sin(_elapsed * 12.0)
		_target_visual.scale = _base_target_scale * pulse
	if t >= 1.0:
		_playing = false
		visible = false


func _place_hand(g: Vector2) -> void:
	if _hand == null:
		return
	_hand.global_position = g - _hand.size * 0.5
