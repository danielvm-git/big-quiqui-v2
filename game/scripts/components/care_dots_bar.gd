# story: e02s02
# story: e12s03
class_name CareDotsBar
extends Control
## Care-loop dots (five) or in-room step dots (N). Never takes input.

const CARE_DOT_COUNT: int = 5
const DOT_COUNT: int = 5
const FILLED_PATH: String = "res://assets/art/ui/progress_dot.png"
const EMPTY_PATH: String = "res://assets/art/ui/progress_dot_empty.png"
const DOT_GAP: int = 24

var _completed: int = 0
var _target_count: int = DOT_COUNT
var _dots: Array[TextureRect] = []
var _row: HBoxContainer = null


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_row = HBoxContainer.new()
	_row.name = "DotRow"
	_row.set_anchors_preset(PRESET_FULL_RECT)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", DOT_GAP)
	_row.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_row)
	_rebuild_dots(DOT_COUNT)


func _make_dot(index: int) -> TextureRect:
	var dot: TextureRect = TextureRect.new()
	dot.name = "Dot%d" % index
	dot.mouse_filter = MOUSE_FILTER_IGNORE
	dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return dot


## Mirrors how many of the five care steps are done. Clamped to 0..5.
func set_completed_steps(count: int) -> void:
	_target_count = CARE_DOT_COUNT
	_rebuild_dots(CARE_DOT_COUNT)
	_completed = clampi(count, 0, CARE_DOT_COUNT)
	_apply()


## In-room step progress: N dots for N steps in the def.
func set_step_progress(completed: int, total: int) -> void:
	var safe_total: int = clampi(total, 1, 9)
	_target_count = safe_total
	_rebuild_dots(safe_total)
	_completed = clampi(completed, 0, safe_total)
	_apply()


func completed_steps() -> int:
	return _completed


## The resolved texture path per dot, left to right — test observable.
func dot_textures() -> Array[String]:
	var paths: Array[String] = []
	for dot: TextureRect in _dots:
		var texture: Texture2D = dot.texture
		paths.append(texture.resource_path if texture != null else "")
	return paths


func dot_count() -> int:
	return _dots.size()


func _rebuild_dots(count: int) -> void:
	if _row == null:
		return
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.free()
	_dots.clear()
	for index: int in range(count):
		var dot: TextureRect = _make_dot(index)
		_row.add_child(dot)
		_dots.append(dot)


func _apply() -> void:
	for index: int in range(_dots.size()):
		var path: String = FILLED_PATH if index < _completed else EMPTY_PATH
		_dots[index].texture = load(path) as Texture2D
