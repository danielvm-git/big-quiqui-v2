# story: e13s03
class_name TouchPad
extends Control
## The touch surface under a room. It forwards one stream of press, move and lift with the finger
## index, and drops the mouse echo Godot makes for every touch (`device == -1`).

signal pressed(point: Vector2, index: int)
signal moved(point: Vector2, index: int)
signal released(point: Vector2, index: int)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _gui_input(event: InputEvent) -> void:
	if event.device == -1:
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		_forward(touch.position, touch.index, touch.pressed)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		moved.emit(drag.position, drag.index)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_forward((event as InputEventMouseButton).position, 0, (event as InputEventMouseButton).pressed)
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask != 0:
		moved.emit((event as InputEventMouseMotion).position, 0)


func _forward(point: Vector2, index: int, down: bool) -> void:
	if down:
		pressed.emit(point, index)
	else:
		released.emit(point, index)
