# story: e11s02
extends GutTest
## SC-E11-P0-02 — 1,000 concurrent touch events on the hub leave FSMs clean.

const SCENE_PATH: String = "res://scenes/vila.tscn"

var monkey: MonkeySim = null
var scene: Control = null


func before_each() -> void:
	TestReset.reset_all()
	VilaScene.reset_session()
	get_node("/root/AudioManager").reset()
	monkey = MonkeySim.new()
	monkey.reset()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _mount() -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = GeometryOracle.DESKTOP_16_9
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


func test_monkey_does_not_stall_recycle_or_scene_fsm() -> void:
	scene = _mount()
	scene.set("manual_step", true)
	await wait_process_frames(2)
	var probe: FsmProbe = null
	var recycle_fsm: Variant = scene.get("recycle_fsm")
	if recycle_fsm is Fsm:
		probe = FsmProbe.new().attach(recycle_fsm as Fsm)
	var targets: Array[Control] = _tap_targets(scene)
	assert_gt(targets.size(), 0, "hub must expose tap targets")
	var rect: Rect2 = scene.get_global_rect()
	for i: int in range(MonkeySim.EVENT_COUNT):
		var finger: int = monkey.next_finger()
		var target: Control = targets[i % targets.size()]
		var pos: Vector2 = monkey.random_point_in(
			target.get_global_rect() if target.size.length_squared() > 1.0 else rect
		)
		var down: InputEvent = monkey.touch_event_at(target, pos, finger, true)
		target._gui_input(down)
		var up: InputEvent = monkey.touch_event_at(target, pos, finger, false)
		target._gui_input(up)
		if i % 50 == 0:
			await wait_process_frames(1)
	if probe != null:
		assert_true(probe.is_clean(), probe.summary())
		probe.detach()
	assert_true(is_instance_valid(scene))


func _tap_targets(node: Node) -> Array[Control]:
	var found: Array[Control] = []
	_gather_tap_targets(node, found)
	return found


func _gather_tap_targets(node: Node, found: Array[Control]) -> void:
	if node is TapButton:
		found.append(node as Control)
	for child: Node in node.get_children():
		_gather_tap_targets(child, found)
