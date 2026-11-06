# story: e03s01
class_name TouchDraggableTestCase
extends GutTest
## Shared fixture for the TouchDraggable tests. Every event goes through
## `TouchSim.gui_event`, so the component sees the local positions real GUI dispatch
## would give it.

const HOME: Vector2 = Vector2(100.0, 120.0)
const FOOD_SIZE: Vector2 = Vector2(148.0, 148.0)
const TARGET_POS: Vector2 = Vector2(900.0, 400.0)
const TARGET_SIZE: Vector2 = Vector2(200.0, 200.0)
const ON_TARGET: Vector2 = Vector2(1000.0, 500.0)
const MISS: Vector2 = Vector2(600.0, 800.0)

var food: TouchDraggable = null
var target: Control = null
var probe: FsmProbe = null
var started: int = 0
var ended: int = 0
var consumed: int = 0
var moved_points: Array[Vector2] = []


func before_each() -> void:
	target = _make_target(self, TARGET_POS)
	food = _make_food(self, HOME, "Cenoura")
	probe = FsmProbe.new().attach(food.fsm)
	started = 0
	ended = 0
	consumed = 0
	moved_points = []
	food.drag_started.connect(func() -> void: started += 1)
	food.drag_ended.connect(func() -> void: ended += 1)
	food.consumed.connect(func() -> void: consumed += 1)
	food.drag_moved.connect(func(point: Vector2) -> void: moved_points.append(point))


func _make_target(parent: Node, at: Vector2) -> Control:
	var control: Control = Control.new()
	control.position = at
	control.size = TARGET_SIZE
	parent.add_child(control)
	autofree(control)
	return control


func _make_food(parent: Node, at: Vector2, node_name: String) -> TouchDraggable:
	var draggable: TouchDraggable = TouchDraggable.new()
	draggable.name = node_name
	draggable.position = at
	draggable.size = FOOD_SIZE
	draggable.manual_step = true
	draggable.drop_target = target
	parent.add_child(draggable)
	autofree(draggable)
	return draggable


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _send(control: Control, event: InputEvent) -> void:
	control._gui_input(TouchSim.gui_event(control, event))


func _touch(point: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	return event


func _drag(point: Vector2, index: int = 0) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = point
	return event


func _mouse(point: Vector2, pressed: bool, device: int = 0) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = pressed
	event.device = device
	return event


func _mouse_move(point: Vector2, device: int = 0) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.device = device
	return event


func _center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


func _diary() -> Node:
	return get_node("/root/Log")


func _last_line() -> Dictionary:
	return _diary().get("last_line") as Dictionary


func _assert_near(actual: Vector2, expected: Vector2, label: String) -> void:
	assert_true(actual.is_equal_approx(expected), "%s: got %s, want %s" % [label, actual, expected])
