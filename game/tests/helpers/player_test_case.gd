# story: e13s04
class_name PlayerTestCase
extends GutTest
## Mounts the real `ScenePlayer` on a def and sends finger events to the controls a template
## built. Godot's headless viewport does not dispatch GUI input, so events go to `_gui_input`
## with the local position GUI dispatch would give (the pattern `TouchDraggableTestCase` uses).

const PLAYER_PATH: String = "res://scenes/scene_player.tscn"


func mount(def: SceneDef, size: Vector2i = GeometryOracle.DESKTOP_16_9) -> ScenePlayer:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(PLAYER_PATH) as PackedScene
	var player: ScenePlayer = packed.instantiate() as ScenePlayer
	player.manual_step = true
	player.def_override = def
	viewport.add_child(player)
	for _i: int in range(10):
		await wait_process_frames(1)
		if player.loaded_def != null:
			break
	return player


func send(control: Control, event: InputEvent) -> void:
	control._gui_input(TouchSim.gui_event(control, event))


func touch(point: Vector2, pressed: bool, index: int = 0, device: int = 0) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	event.device = device
	return event


func drag(point: Vector2, index: int = 0, device: int = 0) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = point
	event.device = device
	return event


## Press on `tool`, drag over every cell centre of `hull`, lift.
func rub_hull(tool: Control, hull: PackedVector2Array) -> void:
	send(tool, touch(tool.get_global_rect().get_center(), true))
	var box: Rect2 = Rect2(hull[0], Vector2.ZERO)
	for point: Vector2 in hull:
		box = box.expand(point)
	for col: int in range(RubPrimitive.CELL_EDGE):
		for row: int in range(RubPrimitive.CELL_EDGE):
			var step: Vector2 = box.size / float(RubPrimitive.CELL_EDGE)
			var at: Vector2 = box.position + Vector2((float(col) + 0.5) * step.x, (float(row) + 0.5) * step.y)
			send(tool, drag(at))
	send(tool, touch(box.get_center(), false))


## The live tool in the tray. A step that just ended may still have a node queued for free
## under the same name, so the lookup is by type, not by path.
func rub_tool(player: ScenePlayer) -> TouchDraggable:
	for child: Node in player.get_node("TrayZone").get_children():
		if child is TouchDraggable and not child.is_queued_for_deletion():
			return child as TouchDraggable
	return null
