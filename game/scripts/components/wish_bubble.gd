# story: e02s02
class_name WishBubble
extends Control
## The wish bubble (balao_desejo) is a two-state overlay: HIDDEN or SHOWN with
## the icon of what QuiQui wants next. It breathes with a subtle pulse while
## shown (DESIGN.md §4.3) and never eats a tap — it is a prompt, not a button.

const STATE_HIDDEN: String = "HIDDEN"
const STATE_SHOWN: String = "SHOWN"

const LEGAL_EDGES: Dictionary = {
	STATE_HIDDEN: [STATE_SHOWN],
	STATE_SHOWN: [STATE_HIDDEN],
}

const FRAME_PATH: String = "res://assets/art/ui/balao_desejo.png"
const ART_ROOT: String = "res://assets/art/"
## Only a literal art path may be loaded: no `.`, `..` or scheme tricks. Prefix
## and suffix checks alone accepted `res://assets/art/../../x.png`.
const ART_PATH_PATTERN: String = "^res://assets/art/([a-z0-9_]+/)*[a-z0-9_]+\\.png$"

const PULSE_AMPLITUDE: float = 0.04
const PULSE_SPEED: float = 3.0

var fsm: Fsm = null
## Test seam: when true, `_process` does nothing and only `advance()` steps the
## pulse, so a test's timeline is the only timeline.
var manual_step: bool = false

var _frame: TextureRect = null
var _icon: TextureRect = null
var _visual: Control = null
var _wish_id: String = ""
var _pulse_time: float = 0.0
var _pulse_scale: float = 1.0
var _art_path_re: RegEx = RegEx.new()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_art_path_re.compile(ART_PATH_PATTERN)
	fsm = Fsm.new(STATE_HIDDEN, LEGAL_EDGES, {})
	_build_visual()
	_apply_visibility()


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


## Steps the pulse. Time only accumulates while shown, so a hidden bubble is
## always exactly 1.0 and replaying a timeline reproduces it (pure function of
## accumulated time).
func advance(delta: float) -> void:
	if fsm == null or _visual == null:
		return
	if fsm.state != STATE_SHOWN:
		# Hidden means rest: the reported scale and the actual transform must
		# agree, or a hide mid-pulse leaves the bubble permanently off-size.
		_pulse_scale = 1.0
		_visual.scale = Vector2.ONE
		return
	_pulse_time += maxf(delta, 0.0)
	_pulse_scale = 1.0 + PULSE_AMPLITUDE * sin(_pulse_time * PULSE_SPEED)
	_visual.pivot_offset = _visual.size * 0.5
	_visual.scale = Vector2(_pulse_scale, _pulse_scale)


## Shows the bubble with the icon at `icon_path` (under `res://assets/art/`).
## Returns false (and stays hidden) when the art is missing.
func show_wish(icon_path: String) -> bool:
	if not _is_valid_art_path(icon_path):
		_emit("ui.wish_rejected", {"path": _slug(icon_path)})
		return false
	if not ResourceLoader.exists(icon_path) or not ResourceLoader.exists(FRAME_PATH):
		_emit("ui.missing_art", {"path": _slug(icon_path)})
		return false

	_icon.texture = load(icon_path) as Texture2D
	_wish_id = icon_path.get_file().get_basename()
	if fsm.state == STATE_HIDDEN:
		fsm.transition_to(STATE_SHOWN)
	_pulse_time = 0.0
	_apply_visibility()
	_emit("ui.wish_show", {"icon": _wish_id})
	return true


func hide_wish() -> bool:
	_wish_id = ""
	_pulse_time = 0.0
	_pulse_scale = 1.0
	if _icon != null:
		_icon.texture = null
	if _visual != null:
		_visual.scale = Vector2.ONE
	var hidden: bool = fsm.transition_to(STATE_HIDDEN)
	_apply_visibility()
	if hidden:
		_emit("ui.wish_hide", {})
	return hidden


func is_showing() -> bool:
	return fsm.state == STATE_SHOWN


func wish_id() -> String:
	return _wish_id


func icon_texture() -> Texture2D:
	return _icon.texture


## Current pulse scale (1.0 while hidden) — test observable.
func pulse_scale() -> float:
	return _pulse_scale


func reset() -> void:
	_wish_id = ""
	_pulse_time = 0.0
	_pulse_scale = 1.0
	if _icon != null:
		_icon.texture = null
	if fsm != null and fsm.state != STATE_HIDDEN:
		fsm.transition_to(STATE_HIDDEN)
	_apply_visibility()


func _build_visual() -> void:
	_visual = Control.new()
	_visual.name = "Visual"
	_visual.set_anchors_preset(PRESET_FULL_RECT)
	_visual.mouse_filter = MOUSE_FILTER_IGNORE
	_visual.pivot_offset = size * 0.5
	add_child(_visual)

	_frame = TextureRect.new()
	_frame.name = "Frame"
	_frame.texture = load(FRAME_PATH) as Texture2D
	_frame.set_anchors_preset(PRESET_FULL_RECT)
	_frame.mouse_filter = MOUSE_FILTER_IGNORE
	_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_visual.add_child(_frame)

	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.set_anchors_preset(PRESET_CENTER)
	_icon.mouse_filter = MOUSE_FILTER_IGNORE
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.anchor_left = 0.26
	_icon.anchor_right = 0.74
	_icon.anchor_top = 0.18
	_icon.anchor_bottom = 0.66
	_visual.add_child(_icon)


func _is_valid_art_path(path: String) -> bool:
	if path.is_empty() or not path.begins_with(ART_ROOT):
		return false
	return _art_path_re.search(path) != null


func _apply_visibility() -> void:
	visible = fsm.state == STATE_SHOWN


func _slug(path: String) -> String:
	var base: String = path.get_file().to_lower()
	return "art." + (base if not base.is_empty() else "unknown")


func _emit(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
