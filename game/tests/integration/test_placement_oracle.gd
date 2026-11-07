# story: e09s04
extends GutTest
## SC-E09-P0-01/02/03, SC-E09-P1-05/06 — the same room on both canvases, and an oracle
## that is allowed to fail.

const SCENE_PATH: String = "res://scenes/casinha.tscn"

var scene: Control = null


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _fill(ids: Array[String]) -> void:
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_coins", 1000)
	for id: String in ids:
		assert_true(progress.call("buy_furniture", id, 1), id)


func _mount(size: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var instance: Node = (load(SCENE_PATH) as PackedScene).instantiate()
	viewport.add_child(instance)
	return instance as Control


func _area(scene_root: Control) -> Rect2:
	return (scene_root.get_node("PlacementArea") as Control).get_global_rect()


func _drag_to_ratio(prop: Control, area: Rect2, ratio: Vector2) -> void:
	var target: Vector2 = area.position + area.size * ratio
	for event: InputEvent in TouchSim.drag_events(prop, target, 8, true):
		prop._gui_input(TouchSim.gui_event(prop, event))


func _saved() -> Array[Dictionary]:
	return get_node("/root/ProgressManager").call("placed") as Array[Dictionary]


func test_a_placement_from_one_canvas_restores_within_two_percent_on_another() -> void:
	_fill(["mesa", "tapete"])
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("place_furniture", "mesa", 0.30, 0.60)
	progress.call("place_furniture", "tapete", 0.70, 0.40)

	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	var oracle: PlacementOracle = PlacementOracle.new()
	assert_true(
		oracle.audit_normalized(GeometryOracle.DESKTOP_16_9, GeometryOracle.DESKTOP_16_9, _saved(), scene).is_empty(),
		oracle.summary(),
	)
	scene.queue_free()

	scene = _mount(GeometryOracle.IPAD_4_3)
	await wait_process_frames(3)
	oracle = PlacementOracle.new()
	assert_true(
		oracle.audit_normalized(GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3, _saved(), scene).is_empty(),
		oracle.summary(),
	)


func test_the_same_finger_ratio_saves_the_same_coordinate_on_both_canvases() -> void:
	_fill(["mesa"])
	var progress: Node = get_node("/root/ProgressManager")
	var ratios: Array[Vector2] = [Vector2(0.35, 0.65)]
	var captured: Array[Vector2] = []
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		progress.call("remove_furniture", "mesa")
		scene = _mount(size)
		await wait_process_frames(3)
		var prop: Control = scene.get_node("Prop_mesa") as Control
		_drag_to_ratio(prop, _area(scene), ratios[0])
		captured.append(Vector2(float(_saved()[0]["x"]), float(_saved()[0]["y"])))
		scene.queue_free()
		scene = null

	assert_true(
		captured[0].distance_to(captured[1]) <= PlacementOracle.RATIO_TOLERANCE,
		"16:9 saved %s, 4:3 saved %s" % [captured[0], captured[1]],
	)


func test_a_tampered_coordinate_is_clamped_not_crashed() -> void:
	_fill(["cama"])
	var progress: Node = get_node("/root/ProgressManager")
	var tampered: Array[Dictionary] = [{"id": "cama", "x": 4.0, "y": -2.0}]
	progress.get("data").placed_furniture = tampered
	progress.call("save")
	progress.call("load_or_default")

	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	var prop: Control = scene.get_node_or_null("Prop_cama") as Control
	assert_not_null(prop, "a clamped piece still exists")
	var ratio: Vector2 = PlacementOracle.new().normalized_center_of(prop, scene.get_node("PlacementArea") as Control)
	assert_true(ratio.x >= 0.0 and ratio.x <= 1.0, "x=%f" % ratio.x)
	assert_true(ratio.y >= 0.0 and ratio.y <= 1.0, "y=%f" % ratio.y)


func test_the_oracle_reports_a_piece_that_moved_ten_percent() -> void:
	_fill(["sofa"])
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("place_furniture", "sofa", 0.50, 0.50)
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	var oracle: PlacementOracle = PlacementOracle.new()
	assert_true(
		oracle.audit_normalized(GeometryOracle.DESKTOP_16_9, GeometryOracle.DESKTOP_16_9, _saved(), scene).is_empty()
	)

	var prop: Control = scene.get_node("Prop_sofa") as Control
	var area: Rect2 = _area(scene)
	prop.position += Vector2(area.size.x * 0.10, 0.0)

	oracle = PlacementOracle.new()
	var findings: Array[String] = oracle.audit_normalized(
		GeometryOracle.DESKTOP_16_9, GeometryOracle.DESKTOP_16_9, _saved(), scene
	)
	assert_eq(findings.size(), 1, "a green oracle that cannot fail is not an oracle")
	assert_string_contains(findings[0], "sofa")


func test_an_empty_save_is_a_finding_not_a_pass() -> void:
	_fill(["mesa"])
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	var oracle: PlacementOracle = PlacementOracle.new()
	var findings: Array[String] = oracle.audit_normalized(
		GeometryOracle.DESKTOP_16_9, GeometryOracle.DESKTOP_16_9, [] as Array[Dictionary], scene
	)
	assert_eq(findings.size(), 1, "nothing placed proves nothing")
