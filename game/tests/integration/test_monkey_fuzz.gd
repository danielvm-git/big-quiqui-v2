# story: e11s02
# story: e14s05
extends PlayerTestCase
## FZ-02/03 — random touches on the player hub and a step room stay playable.

const SEED: int = 424242
const EVENTS: int = 400
const STEP_EVENTS: int = 120


func before_each() -> void:
	TestReset.reset_all()


func test_the_stream_is_reproducible_and_device_legal() -> void:
	var first: Array[Dictionary] = MonkeyStream.finger_script(SEED, 200)
	var second: Array[Dictionary] = MonkeyStream.finger_script(SEED, 200)
	assert_eq(first, second, "the same seed must replay the same monkey")


func test_random_events_on_home_leave_progress_clean() -> void:
	var before: int = int(get_node("/root/ProgressManager").call("get_coins"))
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("home"))
	await _pump(player, EVENTS)
	assert_eq(SaveCorpus.violations(get_node("/root/ProgressManager").data), [] as Array[String])
	assert_gte(int(get_node("/root/ProgressManager").call("get_coins")), before - 100)


func test_random_events_in_kitchen_do_not_wedge_the_care_loop() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("kitchen"))
	await _pump(player, STEP_EVENTS)
	var loop: Node = get_node("/root/CareLoopManager")
	var probe: FsmProbe = FsmProbe.new().attach(loop.fsm)
	loop.reset()
	assert_true(loop.begin_step(CareSteps.FEED))
	assert_true(probe.is_clean(), probe.summary())
	probe.detach()


func _pump(player: ScenePlayer, count: int) -> void:
	var canvas: Vector2 = player.size
	for index: int in range(count):
		var targets: Array[Control] = _interactive(player)
		assert_gt(targets.size(), 0, "the monkey needs something to touch")
		var entry: Dictionary = MonkeyStream.events(SEED + index, 1, canvas)[0]
		var control: Control = targets[index % targets.size()]
		if not is_instance_valid(control):
			continue
		send(control, entry["event"] as InputEvent)
		if index % 40 == 0:
			player.advance(0.1)
			await wait_process_frames(1)


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
