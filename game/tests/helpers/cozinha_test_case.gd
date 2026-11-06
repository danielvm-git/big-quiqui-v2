# story: e03s03
class_name CozinhaTestCase
extends GutTest
## Shared fixture for KitchenScene integration tests.

const SCENE_PATH: String = "res://scenes/cozinha.tscn"
const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/cozinha.ogg"
const FIXED_SEED: int = 20261105
const STEP_SEC: float = 1.0
const AWAY_FROM_MOUTH: Vector2 = Vector2(150.0, 300.0)
const FOOD_COUNT: int = 3
const MIN_FOOD_GAP: float = 24.0
const MIN_MOUTH_DISTANCE: float = 220.0
const TRAY_CENTRE_ABOVE_BOTTOM: float = 156.0

var scene: KitchenScene = null
var requested: Array[String] = []
var loop_state_at_request: Array[String] = []
var refused_requests: Array[String] = []
var clm: Node = null
var sm: Node = null
var am: Node = null


func before_all() -> void:
	clm = get_node("/root/CareLoopManager")
	sm = get_node("/root/SceneManager")
	am = get_node("/root/AudioManager")
	sm.scene_requested.connect(_on_scene_requested)
	sm.transition_rejected.connect(func(path: String, _reason: String) -> void: refused_requests.append(path))


func before_each() -> void:
	TestReset.reset_all()
	requested = []
	loop_state_at_request = []
	refused_requests = []


func after_each() -> void:
	sm.manual_step = false
	sm.loader = Callable()
	am.reset()
	scene = null


func _on_scene_requested(path: String, _queued: bool) -> void:
	requested.append(path)
	loop_state_at_request.append(clm.state_id())


func _mount(size: Vector2i, seed_value: int = FIXED_SEED) -> KitchenScene:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_not_null(packed, "cozinha.tscn must load")
	var instance: KitchenScene = packed.instantiate() as KitchenScene
	instance.manual_step = true
	instance.seed_value = seed_value
	viewport.add_child(instance)
	return instance


func _enter(size: Vector2i = GeometryOracle.DESKTOP_16_9) -> KitchenScene:
	scene = _mount(size)
	await wait_process_frames(3)
	scene.rig.manual_step = true
	for index: int in range(FOOD_COUNT):
		scene.food(index).manual_step = true
	return scene


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _touch(point: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	return event


func _drag(point: Vector2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.position = point
	return event


func _press(index: int) -> void:
	var food: TouchDraggable = scene.food(index)
	food._gui_input(TouchSim.gui_event(food, _touch(food.get_global_rect().get_center(), true)))


func _move(index: int, point: Vector2) -> void:
	var food: TouchDraggable = scene.food(index)
	food._gui_input(TouchSim.gui_event(food, _drag(point)))


func _release(index: int, point: Vector2) -> void:
	var food: TouchDraggable = scene.food(index)
	food._gui_input(TouchSim.gui_event(food, _touch(point, false)))


func _feed(index: int) -> void:
	var food: TouchDraggable = scene.food(index)
	_deliver(food, TouchSim.drag_events(food, scene.rig.mouth_global_center()))


func _finish_reactions() -> void:
	scene.advance(STEP_SEC)
	scene.advance(STEP_SEC)


func _feed_all() -> void:
	for index: int in range(FOOD_COUNT):
		_feed(index)
		_finish_reactions()


func _tap_home() -> void:
	var home: TapButton = scene.get_node("HomeButton") as TapButton
	for event: InputEvent in TouchSim.tap_events(home, true):
		home._gui_input(event)


func _art_name(index: int) -> String:
	return scene.tray[index].art_path.get_file().get_basename()


func _ids(items: Array[ItemData]) -> Array[String]:
	var ids: Array[String] = []
	for item: ItemData in items:
		ids.append(item.id)
	return ids
