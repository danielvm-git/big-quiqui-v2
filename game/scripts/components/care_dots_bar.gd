# story: e02s02
class_name CareDotsBar
extends Control
## Five dots, one per completed care step (FEED..SLEEP): filled on the left,
## empty on the right. A pure status display — it mirrors `completed_steps()`
## from CareLoopManager and never takes input.

const DOT_COUNT: int = 5
const FILLED_PATH: String = "res://assets/art/ui/bolinha_progresso.png"
const EMPTY_PATH: String = "res://assets/art/ui/bolinha_progresso_vazia.png"
const DOT_GAP: int = 24

var _completed: int = 0
var _dots: Array[TextureRect] = []


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "DotRow"
	row.set_anchors_preset(PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", DOT_GAP)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(row)

	for index: int in range(DOT_COUNT):
		var dot: TextureRect = TextureRect.new()
		dot.name = "Dot%d" % index
		dot.mouse_filter = MOUSE_FILTER_IGNORE
		dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		_dots.append(dot)

	_apply()


## Mirrors how many of the five care steps are done. Clamped to 0..5.
func set_completed_steps(count: int) -> void:
	_completed = clampi(count, 0, DOT_COUNT)
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


func _apply() -> void:
	for index: int in range(_dots.size()):
		var path: String = FILLED_PATH if index < _completed else EMPTY_PATH
		_dots[index].texture = load(path) as Texture2D
