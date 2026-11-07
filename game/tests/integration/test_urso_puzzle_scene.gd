# story: e10s02
extends GutTest
## SC-E10-P0-08..11, P1-12, P1-13 — the magnetic jigsaw puzzle: four quadrant
## pieces dragged to ghost slots, one payout, echo-proof drags, both aspects,
## replay + Home to the festa.

const SCENE_PATH: String = "res://scenes/urso_puzzle.tscn"
const BEAR_SCRIPT = preload("res://scripts/scenes/urso_puzzle.gd")
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
	while str(scene.get("fsm").state) != BearPuzzleScene.STATE_PLAYING:
		scene.call("advance", 0.05)


func _drag_piece_to(piece: PuzzlePiece, target: Control, with_mouse_echo: bool = true) -> void:
	var events: Array[InputEvent] = TouchSim.drag_events(
		piece.draggable, target.get_global_rect().get_center(), with_mouse_echo
	)
	for event: InputEvent in events:
		piece.draggable._gui_input(TouchSim.gui_event(piece.draggable, event))


func _tap(button: Control) -> void:
	for event: InputEvent in TouchSim.tap_events(button, true):
		button._gui_input(event)


# SC-E10-P0-11
func test_urso_puzzle_scene_passes_oracle_on_both_aspects() -> void:
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var mounted: Control = _mount(size)
		await wait_process_frames(2)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), oracle.summary())
		var home: Control = mounted.get_node("HomeButton") as Control
		assert_gte(home.get_global_rect().size.x, 120.0, "home width")
		assert_gte(home.get_global_rect().size.y, 120.0, "home height")
		var replay: Control = mounted.get_node("ReplayButton") as Control
		assert_gte(replay.get_global_rect().size.x, 120.0, "replay width")
		assert_gte(replay.get_global_rect().size.y, 120.0, "replay height")
		for i: int in range(4):
			var piece: Control = mounted.get_node("Tray/Piece%d" % i) as Control
			assert_gte(piece.get_global_rect().size.x, 120.0, "piece %d width" % i)
			assert_gte(piece.get_global_rect().size.y, 120.0, "piece %d height" % i)
		mounted.queue_free()


# SC-E10-P1-13
func test_seeded_tray_and_visible_answer_key_slots() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.call("seed_shuffle", [2, 0, 3, 1] as Array[int])
	var order: Array = scene.call("tray_order") as Array
	assert_eq(order, [2, 0, 3, 1], "tray matches seeded permutation")
	for i: int in range(4):
		var slot: Control = scene.get_node("Board/Slot%d" % i) as Control
		assert_not_null(slot)
		var ghost: TextureRect = slot.get_node_or_null("Ghost") as TextureRect
		assert_not_null(ghost, "ghost answer key present in slot %d" % i)
		var atlas: AtlasTexture = ghost.texture as AtlasTexture
		assert_not_null(atlas, "ghost texture is atlas")
		assert_eq(
			atlas.region,
			PuzzlePiece.quadrant_region(i, Vector2(1024.0, 1024.0)),
			"ghost region matches quadrant %d" % i
		)


# SC-E10-P0-09
func test_drag_onto_wrong_slot_or_floor_flies_home_and_locks_nothing() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	_ready_to_play()
	var piece0: PuzzlePiece = scene.get_node("Tray/Piece0") as PuzzlePiece
	var slot1: Control = scene.get_node("Board/Slot1") as Control
	_drag_piece_to(piece0, slot1)
	assert_false(piece0.is_locked(), "wrong slot does not lock")
	assert_eq(int(scene.call("locked_count")), 0)
	var floor_ctrl: Control = Control.new()
	floor_ctrl.position = Vector2(100.0, 100.0)
	floor_ctrl.size = Vector2(50.0, 50.0)
	scene.add_child(floor_ctrl)
	_drag_piece_to(piece0, floor_ctrl)
	assert_false(piece0.is_locked(), "floor does not lock")
	assert_eq(int(scene.call("locked_count")), 0)
	floor_ctrl.queue_free()


# SC-E10-P0-08 + P0-10
func test_four_drags_win_once_and_extra_taps_are_echo_proof() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	assert_eq(scene.get_script(), BEAR_SCRIPT)
	var probe: FsmProbe = FsmProbe.new().attach(scene.get("fsm") as Fsm)
	var eco: EconomyData = EconomyData.new()
	eco.minigame_coins = {"urso": 6}
	scene.call("apply_economy", eco)
	var progress: Node = get_node("/root/ProgressManager")
	_ready_to_play()
	for i: int in range(4):
		var piece: PuzzlePiece = scene.get_node("Tray/Piece%d" % i) as PuzzlePiece
		var slot: Control = scene.get_node("Board/Slot%d" % i) as Control
		_drag_piece_to(piece, slot, true)
		assert_true(piece.is_locked(), "piece %d locked" % i)
		assert_eq(int(scene.call("locked_count")), i + 1)
	while str(scene.get("fsm").state) != BearPuzzleScene.STATE_REWARD:
		scene.call("advance", 0.05)
	assert_eq(int(progress.call("get_coins")), 6, "win pays economy coins")
	assert_eq(int(progress.call("stars_of", "urso")), 1, "win grants one star")
	assert_true(probe.is_clean(), "no illegal transitions")
	var piece0: PuzzlePiece = scene.get_node("Tray/Piece0") as PuzzlePiece
	var slot0: Control = scene.get_node("Board/Slot0") as Control
	_drag_piece_to(piece0, slot0)
	assert_eq(int(progress.call("get_coins")), 6, "extra drag in reward pays nothing")


# SC-E10-P1-12
func test_replay_redeals_four_unlocked_pieces_and_home_returns() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	_ready_to_play()
	for i: int in range(4):
		var piece: PuzzlePiece = scene.get_node("Tray/Piece%d" % i) as PuzzlePiece
		var slot: Control = scene.get_node("Board/Slot%d" % i) as Control
		_drag_piece_to(piece, slot)
	while str(scene.get("fsm").state) != BearPuzzleScene.STATE_REWARD:
		scene.call("advance", 0.05)
	var replay: Control = scene.get_node("ReplayButton") as Control
	assert_true(replay.visible, "replay button visible in reward")
	_tap(replay)
	assert_eq(str(scene.get("fsm").state), BearPuzzleScene.STATE_INTRO)
	for i: int in range(4):
		var piece: PuzzlePiece = scene.get_node("Tray/Piece%d" % i) as PuzzlePiece
		assert_false(piece.is_locked(), "piece %d unlocked on replay" % i)
	assert_eq(int(scene.call("locked_count")), 0)
	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	var home: Control = scene.get_node("HomeButton") as Control
	_tap(home)
	assert_eq(requested, [FESTA_PATH] as Array[String])
