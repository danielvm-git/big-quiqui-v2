# story: e11s02
extends GutTest
## FZ-02/03 — 1,000 random touch events, three fingers, two rooms.
##
## The per-scene tests drive the *intended* path with `TouchSim`. This drives the
## unintended one: taps at random points, drags that start on a button, presses that
## never lift. Asserts that the game cannot be put into a state the model forbids.

const SEED: int = 424242
## FZ-02/03 together are the story's 1,000 events: 800 on the hub, 200 in a step room.
const EVENTS: int = 800
const STEP_EVENTS: int = 200

var scene: Control = null


func before_each() -> void:
	TestReset.reset_all()
	scene = null


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null
	TestReset.delete_test_save()


func test_the_stream_is_reproducible_and_device_legal() -> void:
	var first: Array[Dictionary] = MonkeyStream.finger_script(SEED, 200)
	var second: Array[Dictionary] = MonkeyStream.finger_script(SEED, 200)
	assert_eq(first, second, "the same seed must replay the same monkey")

	var down: Dictionary = {}
	for entry: Dictionary in first:
		var finger: int = entry["finger"]
		assert_between(finger, 0, MonkeyStream.MAX_FINGERS - 1)
		if str(entry["kind"]) == "press":
			assert_false(down.get(finger, false), "finger %d pressed twice" % finger)
			down[finger] = true
		elif str(entry["kind"]) == "release":
			assert_true(down.get(finger, false), "finger %d released while up" % finger)
			down[finger] = false


func test_eight_hundred_events_on_the_hub_leave_it_playable() -> void:
	var before: int = int(get_node("/root/ProgressManager").call("get_coins"))
	_mount("res://scenes/casa.tscn")
	await wait_process_frames(2)
	await _pump(EVENTS)
	await wait_process_frames(2)

	assert_eq(SaveCorpus.violations(get_node("/root/ProgressManager").data), [] as Array[String])
	assert_gte(int(get_node("/root/ProgressManager").call("get_coins")), before - 100)
	var manager: Node = get_node("/root/SceneManager")
	var reached: bool = await _drain(manager, 180)
	assert_true(reached, "the hub must not be stuck mid-swap after 3 s")
	assert_eq(str(manager.get("pending_scene")), "", "a parked request must be consumed")


func test_a_burst_inside_a_step_room_does_not_wedge_the_care_loop() -> void:
	_mount("res://scenes/cozinha.tscn")
	await wait_process_frames(2)
	await _pump(STEP_EVENTS)
	await wait_process_frames(2)

	var loop: Node = get_node("/root/CareLoopManager")
	var probe: FsmProbe = FsmProbe.new().attach(loop.fsm)
	loop.reset()
	assert_true(loop.begin_step(CareSteps.FEED), "the loop still accepts a step")
	assert_true(probe.is_clean(), probe.summary())
	probe.detach()
	assert_eq(SaveCorpus.violations(get_node("/root/ProgressManager").data), [] as Array[String])


func test_the_stream_never_adds_nodes_without_bound() -> void:
	_mount("res://scenes/casa.tscn")
	await wait_process_frames(2)
	var baseline: int = _node_count(scene)
	await _pump(STEP_EVENTS)
	await wait_process_frames(3)
	var after: int = _node_count(scene)
	assert_lte(after, baseline + 40, "a random tap must not spawn a permanent node per tap")


# ── pumping ─────────────────────────────────────────────────────────────────


func _mount(path: String) -> void:
	var instance: Node = (load(path) as PackedScene).instantiate()
	add_child_autofree(instance)
	scene = instance as Control


func _pump(count: int) -> void:
	var canvas: Vector2 = scene.size
	var targets: Array[Control] = _interactive(scene)
	assert_gt(targets.size(), 0, "the monkey needs something to touch")
	for index: int in range(count):
		var entry: Dictionary = MonkeyStream.events(SEED + index, 1, canvas)[0]
		var control: Control = targets[index % targets.size()]
		var event: InputEvent = entry["event"] as InputEvent
		_deliver(control, event)
		_deliver(control, MonkeyStream.echo_of(event))
		if index % 50 == 0:
			await wait_process_frames(1)


func _deliver(control: Control, event: InputEvent) -> void:
	if not is_instance_valid(control):
		return
	if control.has_method("_gui_input"):
		control.call("_gui_input", TouchSim.gui_event(control, event))


func _interactive(root: Node) -> Array[Control]:
	var found: Array[Control] = []
	for node: Node in root.find_children("*", "Control", true, false):
		var control: Control = node as Control
		if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		if control.size.x < 1.0 or control.size.y < 1.0:
			continue
		found.append(control)
	return found


func _node_count(root: Node) -> int:
	return root.find_children("*", "", true, false).size()


## Gives the scene machine the watchdog's budget (2.0 s) to come back to IDLE. A real
## wedge is what this test is for, so the wait is bounded and the verdict is explicit.
func _drain(manager: Node, frames: int) -> bool:
	var fsm: Fsm = manager.get("fsm") as Fsm
	for _i: int in range(frames):
		if fsm.state == SceneManager.STATE_IDLE and str(manager.get("pending_scene")) == "":
			return true
		await wait_process_frames(1)
	return fsm.state == SceneManager.STATE_IDLE
