# story: e10s01
extends GutTest
## SC-E10-P0-02..05 — the duck dance: three rounds of follow-the-duck, one payout,
## no fail state, echo-proof taps, both aspects, replay + Home to the festa.

const SCENE_PATH: String = "res://scenes/pato_danca.tscn"
const DUCK_SCRIPT = preload("res://scripts/scenes/pato_danca.gd")

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


func _ready_to_answer() -> void:
	scene.set("manual_step", true)
	while str(scene.get("fsm").state) != DuckDanceScene.STATE_WAITING:
		scene.call("advance", 0.05)


func _tap(button: Control) -> void:
	for event: InputEvent in TouchSim.tap_events(button, true):
		button._gui_input(event)


func _pad(id: String) -> Control:
	return scene.get_node("Pad" + id) as Control


# SC-E10-P0-04
func test_duck_scene_passes_oracle_on_both_aspects() -> void:
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var mounted: Control = _mount(size)
		await wait_process_frames(2)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), oracle.summary())
		for pad_id: String in ["Left", "Centre", "Right"]:
			var pad: Control = mounted.get_node("Pad" + pad_id) as Control
			var rect: Rect2 = pad.get_global_rect()
			assert_gte(rect.size.x, 120.0, pad_id)
			assert_gte(rect.size.y, 120.0, pad_id)
		mounted.queue_free()


# SC-E10-P0-02 + P0-03
func test_three_seeded_answers_win_once_and_a_miss_replays_the_pose() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	assert_eq(scene.get_script(), DUCK_SCRIPT)
	var probe: FsmProbe = FsmProbe.new().attach(scene.get("fsm") as Fsm)
	var eco: EconomyData = EconomyData.new()
	eco.minigame_coins = {"pato": 7}
	scene.call("apply_economy", eco)
	var progress: Node = get_node("/root/ProgressManager")
	scene.call("seed_rounds", ["left", "right", "centre"] as Array[String])
	_ready_to_answer()
	assert_eq(int(scene.get("round_index")), 0)

	# wrong answer: same pose, no round advance, no payout
	_tap(_pad("Right"))
	assert_eq(str(scene.get("fsm").state), DuckDanceScene.STATE_SHOWING, "a miss re-shows the pose")
	_ready_to_answer()
	assert_eq(int(scene.get("round_index")), 0, "the round is not lost")

	# the three correct answers
	for expected_round: int in range(3):
		_tap(_pad(["Left", "Right", "Centre"][expected_round]))
		if expected_round < 2:
			_ready_to_answer()
			assert_eq(int(scene.get("round_index")), expected_round + 1)
	while str(scene.get("fsm").state) != DuckDanceScene.STATE_REWARD:
		scene.call("advance", 0.05)
	assert_eq(int(progress.call("get_coins")), 7, "the win pays the table coins")
	assert_eq(int(progress.call("stars_of", "pato")), 1, "the win grants one star")

	# echo-proof: extra taps in REWARD pay nothing twice
	_tap(_pad("Left"))
	_tap(_pad("Left"))
	assert_eq(int(progress.call("get_coins")), 7)
	assert_eq(int(progress.call("stars_of", "pato")), 1)
	assert_true(probe.is_clean(), probe.summary())


# SC-E10-P0-04 (echo half)
func test_one_echo_tap_advances_exactly_one_round() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.call("seed_rounds", ["centre", "left", "right"] as Array[String])
	_ready_to_answer()
	_tap(_pad("Centre"))
	assert_eq(int(scene.get("round_index")), 1, "touch + synthesized mouse echo = one answer")


# SC-E10-P0-05
func test_replay_reruns_three_rounds_and_pays_again() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	var eco: EconomyData = EconomyData.new()
	eco.minigame_coins = {"pato": 4}
	scene.call("apply_economy", eco)
	var progress: Node = get_node("/root/ProgressManager")
	scene.call("seed_rounds", ["left", "left", "left"] as Array[String])
	_ready_to_answer()
	for _round: int in range(3):
		_tap(_pad("Left"))
		if str(scene.get("fsm").state) != DuckDanceScene.STATE_REWARD:
			_ready_to_answer()
	assert_eq(int(progress.call("get_coins")), 4)

	scene.call("seed_rounds", ["right", "right", "right"] as Array[String])
	_tap(scene.get_node("ReplayButton") as Control)
	assert_eq(str(scene.get("fsm").state), DuckDanceScene.STATE_INTRO)
	_ready_to_answer()
	for _round: int in range(3):
		_tap(_pad("Right"))
		if str(scene.get("fsm").state) != DuckDanceScene.STATE_REWARD:
			_ready_to_answer()
	assert_eq(int(progress.call("get_coins")), 8, "a replay pays again by design")
	assert_eq(int(progress.call("stars_of", "pato")), 2, "the star climbs to mastery, capped later")


# SC-E10-P0-05
func test_home_returns_to_the_festa() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.call("seed_rounds", ["left", "left", "left"] as Array[String])
	_ready_to_answer()
	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	_tap(scene.get_node("HomeButton") as Control)
	assert_eq(requested, ["res://scenes/festa.tscn"] as Array[String])
