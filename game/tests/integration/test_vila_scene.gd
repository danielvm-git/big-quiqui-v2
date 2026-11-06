# story: e08s01
extends GutTest
## SC-E08-P0-01..02, SC-E08-P1-03..05 — the outdoor hub layout, honest pending
## navigation, wish escalation and touch reset.

const SCENE_PATH: String = "res://scenes/vila.tscn"
const CASA_PATH: String = "res://scenes/casa.tscn"
const VILA_SCRIPT = preload("res://scripts/scenes/vila.gd")

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
	assert_not_null(packed, "vila.tscn must load")
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


func test_vila_boots_with_six_pois_and_oracle_passes_both_aspects() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		var mounted: Control = _mount(size)
		await wait_process_frames(2)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])
		var poi_ids: Array[String] = ["CASA", "RODA", "RECYCLING", "MERCADO", "CASINHA", "FESTA"]
		for poi_id: String in poi_ids:
			var door: TapButton = mounted.get_node_or_null("Poi" + poi_id) as TapButton
			assert_not_null(door, "missing POI %s" % poi_id)
			assert_true(door.is_in_group(GeometryOracle.HIT_GROUP), poi_id)
			var rect: Rect2 = door.get_global_rect()
			assert_gte(rect.size.x, 120.0, poi_id)
			assert_gte(rect.size.y, 120.0, poi_id)
		mounted.queue_free()


func test_pending_poi_logs_scene_pending_and_casa_navigates() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	assert_eq(scene.get_script(), VILA_SCRIPT)
	await wait_process_frames(3)
	var recycling: TapButton = scene.call("poi", "RECYCLING") as TapButton
	for event: InputEvent in TouchSim.tap_events(recycling, true):
		recycling._gui_input(event)
	assert_eq(scene.get("last_pending_slug"), "recycling")

	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	var casa: TapButton = scene.call("poi", "CASA") as TapButton
	for event: InputEvent in TouchSim.tap_events(casa, true):
		casa._gui_input(event)
	assert_eq(requested, [CASA_PATH])


func test_escalation_is_monotonic_and_touch_resets_urgency() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	var bubble: WishBubble = scene.get_node("WishBubble") as WishBubble
	var rig: QuiQuiRig = scene.get_node("QuiQuiRig") as QuiQuiRig
	scene.set("manual_step", true)
	assert_eq(bubble.urgency(), 0)
	scene.call("advance", 8.0)
	assert_true(bubble.is_showing())
	assert_eq(bubble.urgency(), 0)
	scene.call("advance", 6.0)
	assert_eq(bubble.urgency(), 1)
	scene.call("advance", 6.0)
	assert_eq(bubble.urgency(), 2)
	scene.call("advance", 100.0)
	assert_eq(bubble.urgency(), 2, "urgency clamps at MAX")
	for event: InputEvent in TouchSim.tap_events(rig, true):
		rig._gui_input(event)
	assert_false(bubble.is_showing())
	assert_eq(bubble.urgency(), 0)


func test_show_wish_defaults_to_urgency_zero() -> void:
	var bubble: WishBubble = WishBubble.new()
	bubble.manual_step = true
	bubble.size = Vector2(220.0, 220.0)
	add_child_autofree(bubble)
	bubble.set_urgency(2)
	assert_eq(bubble.urgency(), 0, "hidden bubble ignores urgency")
	assert_true(bubble.show_wish("res://assets/art/items/cenoura.png"))
	assert_eq(bubble.urgency(), 0)
