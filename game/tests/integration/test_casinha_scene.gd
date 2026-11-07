# story: e09s02
extends GutTest
## SC-E09-P0-04/05/06, SC-E09-P1-08 — the casinha restores what the save says, a drag
## persists the ratio of the room, and a piece she does not own is not there at all.

const SCENE_PATH: String = "res://scenes/casinha.tscn"
const CASINHA_SCRIPT = preload("res://scripts/scenes/casinha.gd")

var scene: Control = null


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _own(id: String) -> void:
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_coins", 100)
	assert_true(progress.call("buy_furniture", id, 1), id)


func _mount(size: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_not_null(packed, "casinha.tscn must load")
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


func _drag(prop: Control, to_global: Vector2) -> void:
	for event: InputEvent in TouchSim.drag_events(prop, to_global, 8, true):
		prop._gui_input(TouchSim.gui_event(prop, event))


func _area(scene_root: Control) -> Rect2:
	return (scene_root.get_node("PlacementArea") as Control).get_global_rect()


func test_an_empty_room_with_two_owned_pieces_passes_the_oracle() -> void:
	_own("mesa")
	_own("tapete")
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var mounted: Control = _mount(size)
		await wait_process_frames(3)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])
		var tray: Array[String] = mounted.call("tray_ids")
		assert_eq(tray.size(), 2, "both owned pieces wait in the tray")
		assert_eq((mounted.call("room_ids") as Array[String]).size(), 0, "an empty room is valid")
		assert_eq(str(mounted.get("fsm").state), CasinhaScene.STATE_EMPTY)
		for id: String in tray:
			var prop: Control = mounted.get_node("Prop_" + id) as Control
			assert_not_null(prop, id)
			assert_gte(prop.get_global_rect().size.x, 120.0, id)
		mounted.queue_free()


func test_a_drag_into_the_room_persists_the_ratio_she_sees() -> void:
	_own("mesa")
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	assert_eq(scene.get_script(), CASINHA_SCRIPT)
	var prop: Control = scene.get_node("Prop_mesa") as Control
	var area: Rect2 = _area(scene)
	_drag(prop, area.position + area.size * Vector2(0.25, 0.75))

	var progress: Node = get_node("/root/ProgressManager")
	assert_eq(int(progress.call("placed_count")), 1, "the drop is persisted")
	assert_eq(str(scene.get("fsm").state), CasinhaScene.STATE_DRESSED)
	var ratio: Vector2 = _saved_ratio()
	assert_almost_eq(ratio.x, 0.25, 0.05)
	assert_almost_eq(ratio.y, 0.75, 0.05)
	var measured: Vector2 = (prop.get_global_rect().get_center() - area.position) / area.size
	assert_true(measured.is_equal_approx(ratio), "the persisted ratio is where she sees it")
	assert_eq((scene.call("tray_ids") as Array[String]).size(), 0, "it left the tray")


func test_a_saved_placement_is_restored_at_its_ratio_on_remount() -> void:
	_own("mesa")
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("place_furniture", "mesa", 0.25, 0.75)
	var ratio: Vector2 = _saved_ratio()

	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	var room: Rect2 = _area(scene)
	var want: Vector2 = room.position + room.size * ratio
	var got: Vector2 = (scene.get_node("Prop_mesa") as Control).get_global_rect().get_center()
	assert_true(got.distance_to(want) < 8.0, "restored at %s, want %s" % [got, want])
	assert_eq(str(scene.get("fsm").state), CasinhaScene.STATE_DRESSED, "a saved room boots dressed")


func _saved_ratio() -> Vector2:
	var saved: Array[Dictionary] = get_node("/root/ProgressManager").call("placed") as Array[Dictionary]
	assert_gte(saved.size(), 1, "a placement must be saved")
	return Vector2(float(saved[0]["x"]), float(saved[0]["y"]))


func test_a_piece_she_does_not_own_is_in_neither_place() -> void:
	_own("cadeira")
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)

	assert_not_null(scene.get_node_or_null("Prop_cadeira"))
	assert_null(scene.get_node_or_null("Prop_cama"), "not bought, not in her room")
	assert_false(bool(scene.call("place", "cama", 0.5, 0.5)), "and it cannot be placed either")
	assert_eq(int(get_node("/root/ProgressManager").call("placed_count")), 0)


func test_home_returns_to_the_casa() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	var home: TapButton = scene.get_node("HomeButton") as TapButton
	for event: InputEvent in TouchSim.tap_events(home, true):
		home._gui_input(event)
	assert_eq(requested, [CasinhaScene.CASA_PATH], "home, once")
