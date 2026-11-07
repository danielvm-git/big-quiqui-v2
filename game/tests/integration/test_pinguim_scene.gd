# story: e10s03
extends GutTest
## SC-E10-P0-17, P1-18, P1-19 — Pinguim catch mini-game integration tests:
## full seeded round via advance only (zero real-time flakiness), lane dragging
## and clamping with mouse-echo safety, both aspects oracle check, replay and Home.

const SCENE_PATH: String = "res://scenes/pinguim_jogo.tscn"
const PENGUIN_SCRIPT = preload("res://scripts/scenes/pinguim_jogo.gd")
const FESTA_PATH: String = "res://scenes/festa.tscn"

var scene: Control = null


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _mount(size: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_not_null(packed)
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


func _ready_to_play() -> void:
	scene.set("manual_step", true)
	while str(scene.get("fsm").state) != PenguinScene.STATE_RUNNING:
		scene.call("advance", 0.05)


func _drag(control: Control, target: Vector2, with_mouse_echo: bool = true) -> void:
	var events: Array[InputEvent] = TouchSim.drag_events(control, target, with_mouse_echo)
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _tap(button: Control) -> void:
	for event: InputEvent in TouchSim.tap_events(button, true):
		button._gui_input(event)


# SC-E10-P0-17
func test_pinguim_scene_passes_oracle_on_both_aspects() -> void:
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var mounted: Control = _mount(size)
		await wait_process_frames(2)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), oracle.summary())
		var home: Control = mounted.get_node("HomeButton") as Control
		assert_gte(home.get_global_rect().size.x, 120.0, "home width")
		assert_gte(home.get_global_rect().size.y, 120.0, "home height")
		var lane: Control = mounted.get_node("IceLane") as Control
		assert_gte(lane.get_global_rect().size.x, 120.0, "lane width")
		assert_gte(lane.get_global_rect().size.y, 120.0, "lane height")
		var replay: Control = mounted.get_node("ReplayButton") as Control
		assert_gte(replay.get_global_rect().size.x, 120.0, "replay width")
		assert_gte(replay.get_global_rect().size.y, 120.0, "replay height")
		var draggable: Control = mounted.get_node("Penguin/Draggable") as Control
		assert_gte(draggable.get_global_rect().size.x, 120.0, "penguin hit width")
		assert_gte(draggable.get_global_rect().size.y, 120.0, "penguin hit height")
		mounted.queue_free()


# SC-E10-P0-17
func test_mouse_echo_drag_moves_penguin_and_clamps_to_lane() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	_ready_to_play()
	var penguin: Control = scene.get_node("Penguin") as Control
	var draggable: Control = scene.get_node("Penguin/Draggable") as Control
	var lane: Control = scene.get_node("IceLane") as Control
	var lane_rect: Rect2 = lane.get_global_rect()
	var half_w: float = penguin.size.x * 0.5

	# Drag to a point inside the lane
	var target_inside: Vector2 = Vector2(lane_rect.position.x + 300.0, lane_rect.get_center().y)
	_drag(draggable, target_inside, true)
	assert_almost_eq(penguin.get_global_rect().get_center().x, target_inside.x, 2.0, "moved to target x")

	# Drag near right edge of lane: clamp stops penguin at max_x
	var target_right: Vector2 = Vector2(lane_rect.end.x - 10.0, lane_rect.get_center().y)
	_drag(draggable, target_right, true)
	assert_almost_eq(penguin.get_global_rect().get_center().x, lane_rect.end.x - half_w, 2.0, "clamped to right edge")

	# Drag near left edge of lane: clamp stops penguin at min_x
	var target_left: Vector2 = Vector2(lane_rect.position.x + 10.0, lane_rect.get_center().y)
	_drag(draggable, target_left, true)
	assert_almost_eq(
		penguin.get_global_rect().get_center().x, lane_rect.position.x + half_w, 2.0, "clamped to left edge"
	)


# SC-E10-P1-19 + SC-E10-P0-14..16
func test_full_seeded_round_via_advance_is_zero_real_time() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	assert_eq(scene.get_script(), PENGUIN_SCRIPT)
	var probe: FsmProbe = FsmProbe.new().attach(scene.get("fsm") as Fsm)
	var progress: Node = get_node("/root/ProgressManager")
	scene.call("seed_spawns", ["bola", "bolha", "bola", "bolha", "bola", "bolha"] as Array[String])
	_ready_to_play()
	assert_eq(int(scene.call("catch_count")), 0)

	var penguin: Control = scene.get_node("Penguin") as Control
	var p_center_x: float = penguin.get_global_rect().get_center().x

	# Spawn and catch 6 items
	for _i: int in range(6):
		scene.call("spawn_item", "bola", p_center_x)
		# Step items down until intercepted (fall_speed is 260px/s, lane is at y=0.78*1080 = 842)
		while int(scene.call("catch_count")) == _i:
			scene.call("advance", 0.1)

	assert_eq(int(scene.call("catch_count")), 6, "all 6 items caught")

	# Finish round by advancing through remainder of ROUND_SEC (20s)
	while str(scene.get("fsm").state) != PenguinScene.STATE_RESULT:
		scene.call("advance", 0.5)

	var total_catches: int = int(scene.call("catch_count"))
	assert_gte(total_catches, 6, "at least 6 items caught")
	assert_eq(int(progress.call("get_coins")), total_catches, "settle pays 1 coin per catch")
	assert_eq(int(progress.call("stars_of", "pinguim")), 1, "granted star for reaching target")

	# Advance to REWARD
	while str(scene.get("fsm").state) != PenguinScene.STATE_REWARD:
		scene.call("advance", 0.1)

	assert_true(probe.is_clean(), "probe recorded no illegal transitions")


# SC-E10-P1-18
func test_home_mid_round_abandons_cleanly() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	_ready_to_play()
	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	var home: Control = scene.get_node("HomeButton") as Control
	_tap(home)
	assert_eq(requested, [FESTA_PATH] as Array[String])
	var progress: Node = get_node("/root/ProgressManager")
	assert_eq(int(progress.call("get_coins")), 0, "abandoned round pays nothing")


# SC-E10-P1-18
func test_replay_restarts_running_round() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	_ready_to_play()
	var penguin: Control = scene.get_node("Penguin") as Control
	scene.call("spawn_item", "bola", penguin.get_global_rect().get_center().x)
	while int(scene.call("catch_count")) == 0:
		scene.call("advance", 0.1)
	assert_eq(int(scene.call("catch_count")), 1)

	# Finish round
	while str(scene.get("fsm").state) != PenguinScene.STATE_REWARD:
		scene.call("advance", 0.5)

	var replay: Control = scene.get_node("ReplayButton") as Control
	assert_true(replay.visible, "replay button visible in reward")
	_tap(replay)
	assert_eq(str(scene.get("fsm").state), PenguinScene.STATE_INTRO)
	assert_eq(int(scene.call("catch_count")), 0, "catches reset on replay")
	_ready_to_play()
	assert_eq(str(scene.get("fsm").state), PenguinScene.STATE_RUNNING)
