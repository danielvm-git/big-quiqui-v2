# story: e11s03
extends CanvasLayer
## FIX-07 — on-device FPS, scene, and last diary lines. Debug builds only; release exports
## still load the autoload but it never paints.

const LABEL_NAME: String = "DevConsoleLabel"

var _label: Label = null


func _ready() -> void:
	if not OS.is_debug_build():
		return
	_label = Label.new()
	_label.name = LABEL_NAME
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label.offset_left = 12.0
	_label.offset_top = 12.0
	_label.add_theme_font_size_override("font_size", 20)
	add_child(_label)
	visible = true
	_refresh()


func _process(_delta: float) -> void:
	if _label == null:
		return
	_refresh()


func is_active() -> bool:
	return _label != null and visible


func _refresh() -> void:
	if _label == null:
		return
	var scene_path: String = ""
	var root: Window = get_tree().root if get_tree() != null else null
	if root != null and root.get_child_count() > 0:
		var current: Node = root.get_child(root.get_child_count() - 1)
		if current != null and current.scene_file_path != "":
			scene_path = current.scene_file_path
	var fps: int = Engine.get_frames_per_second()
	var ev: String = ""
	var log: Node = get_node_or_null("/root/Log")
	if log != null:
		var last: Variant = log.get("last_line")
		if last is Dictionary:
			ev = str((last as Dictionary).get("ev", ""))
	_label.text = "FPS %d | %s | %s" % [fps, scene_path.get_file(), ev]
