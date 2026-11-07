# story: e09s03
extends GutTest
## SC-E09-P0-01..04/05, SC-E09-P1-07 — the party opens at five placed pieces, closes
## when one leaves, and the friends dance the same dance every time.

const SCENE_PATH: String = "res://scenes/festa.tscn"
const FESTA_SCRIPT = preload("res://scripts/scenes/festa.gd")
const FRIEND_IDS: Array[String] = ["pato", "urso", "pinguim"]

var scene: Control = null


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _place(count: int) -> void:
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_coins", 1000)
	var done: int = 0
	for id: String in FurnitureCatalog.FURNITURE_IDS:
		if done >= count:
			return
		assert_true(progress.call("buy_furniture", id, 1), id)
		assert_true(progress.call("place_furniture", id, 0.5, 0.5), id)
		done += 1


func _mount(size: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_not_null(packed, "festa.tscn must load")
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


func test_four_placed_pieces_leave_the_party_locked_and_oracle_clean() -> void:
	_place(4)
	var events_before: int = _count_events("party.locked")
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var mounted: Control = _mount(size)
		await wait_process_frames(3)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])
		assert_eq(mounted.get_script(), FESTA_SCRIPT)
		assert_eq(str(mounted.get("fsm").state), HousePartyScene.STATE_LOCKED)
		assert_false(bool(mounted.call("party_unlocked")), "four is not five")
		assert_true((mounted.get_node("LockBadge") as Control).visible, "the lock is visible")
		for id: String in FRIEND_IDS:
			assert_false((mounted.get_node("Friend_" + id) as Control).visible, id)
		mounted.queue_free()
	assert_gt(_count_events("party.locked"), events_before, "party.locked must be emitted on mount when locked")


func test_five_placed_pieces_start_the_dance() -> void:
	_place(5)
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)

	assert_eq(str(scene.get("fsm").state), HousePartyScene.STATE_DANCING)
	assert_true(bool(scene.call("party_unlocked")))
	assert_false((scene.get_node("LockBadge") as Control).visible, "the lock is gone")
	for id: String in FRIEND_IDS:
		assert_true((scene.get_node("Friend_" + id) as Control).visible, id)


func test_the_bob_is_deterministic_under_manual_step() -> void:
	_place(5)
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var first: Array[float] = _bob_series()
	scene.queue_free()

	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)

	assert_eq(_bob_series(), first, "the same deltas replay the same dance")


func _bob_series() -> Array[float]:
	var seen: Array[float] = []
	for _step: int in range(4):
		scene.call("advance", 0.15)
		var offsets: Dictionary = scene.call("friend_offsets") as Dictionary
		for id: String in FRIEND_IDS:
			seen.append(float(offsets.get(id, 0.0)))
	return seen


func _count_events(ev_id: String) -> int:
	var log: Node = get_node_or_null("/root/Log")
	if log == null:
		return -1
	var path: String = str(log.get("log_path"))
	if not FileAccess.file_exists(path):
		return -1
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var text: String = file.get_as_text()
	file.close()
	var count: int = 0
	for raw: String in text.split("\n"):
		if raw.strip_edges().is_empty():
			continue
		var line: Variant = JSON.parse_string(raw)
		if line is Dictionary and str((line as Dictionary).get("ev", "")) == ev_id:
			count += 1
	return count


func test_the_party_re_locks_when_the_room_drops_below_five() -> void:
	_place(5)
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	var probe: FsmProbe = FsmProbe.new().attach(scene.get("fsm") as Fsm)
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("remove_furniture", "abajur")
	await wait_process_frames(2)

	assert_eq(str(scene.get("fsm").state), HousePartyScene.STATE_LOCKED)
	assert_eq(probe.transitions, ["DANCING->LOCKED"] as Array[String], "one change, one transition")
	assert_true(probe.is_clean(), probe.summary())

	progress.call("place_furniture", "abajur", 0.5, 0.5)
	await wait_process_frames(2)
	assert_eq(probe.transitions, ["DANCING->LOCKED", "LOCKED->DANCING"] as Array[String])


func test_home_and_the_casinha_door_both_navigate_once() -> void:
	_place(5)
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	for node_name: String in ["CasinhaButton", "HomeButton"]:
		var button: TapButton = scene.get_node(node_name) as TapButton
		assert_not_null(button, node_name)
		assert_gte(button.get_global_rect().size.x, 120.0, node_name)
		for event: InputEvent in TouchSim.tap_events(button, true):
			button._gui_input(event)
	assert_eq(requested.size(), 2, "one request per tap, never two")
	assert_eq(requested[0], HousePartyScene.CASINHA_PATH)
	assert_eq(requested[1], HousePartyScene.CASA_PATH)
