# story: e08s01
# story: e08s02
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
		var poi_ids: Array[String] = ["CASA", "RODA", "MERCADO", "CASINHA", "FESTA"]
		for poi_id: String in poi_ids:
			var door: TapButton = mounted.get_node_or_null("Poi" + poi_id) as TapButton
			assert_not_null(door, "missing POI %s" % poi_id)
			assert_true(door.is_in_group(GeometryOracle.HIT_GROUP), poi_id)
			var rect: Rect2 = door.get_global_rect()
			assert_gte(rect.size.x, 120.0, poi_id)
			assert_gte(rect.size.y, 120.0, poi_id)
		var bag: Control = mounted.get_node_or_null("RecycleBag") as Control
		assert_not_null(bag, "recycle bag hit target")
		assert_true(bag.is_in_group(GeometryOracle.HIT_GROUP), "recycle bag")
		mounted.queue_free()


## e09 wired the last three doors (mercado, casinha, festa): every POI now opens a real
## scene, so nothing logs `scene.pending` any more. The pending path stays in the scene
## for the next POI that ships ahead of its scene.
func test_every_poi_door_opens_its_scene_once() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	assert_eq(scene.get_script(), VILA_SCRIPT)
	await wait_process_frames(3)
	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	var doors: Dictionary = {"CASA": CASA_PATH, "RODA": "res://scenes/roda.tscn"}
	doors["MERCADO"] = "res://scenes/mercado.tscn"
	doors["CASINHA"] = "res://scenes/casinha.tscn"
	doors["FESTA"] = "res://scenes/festa.tscn"
	for poi_id: String in doors:
		var door: TapButton = scene.call("poi", poi_id) as TapButton
		assert_not_null(door, poi_id)
		for event: InputEvent in TouchSim.tap_events(door, true):
			door._gui_input(event)
		assert_eq(str(scene.get("last_pending_slug")), "", "%s is no longer pending" % poi_id)
	assert_eq(requested.size(), doors.size(), "one request per door, never two")
	for poi_id: String in doors:
		assert_has(requested, str(doors[poi_id]), poi_id)


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
	assert_true(bubble.show_wish("res://assets/art/items/carrot.png"))
	assert_eq(bubble.urgency(), 0)
