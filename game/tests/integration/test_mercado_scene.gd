# story: e09s01
extends GutTest
## SC-E09-P0-05/06/07 — the store boots clean on both canvases, one tap buys once, a poor
## tap changes nothing.

const SCENE_PATH: String = "res://scenes/mercado.tscn"
const STORE_SCRIPT = preload("res://scripts/scenes/mercado.gd")

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
	assert_not_null(packed, "mercado.tscn must load")
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


func test_store_passes_the_oracle_on_both_aspects() -> void:
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var mounted: Control = _mount(size)
		await wait_process_frames(2)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])
		var shelves: Array[String] = mounted.call("shelf_ids")
		assert_eq(shelves.size(), 12, "one shelf per Lote-6 piece")
		for index: int in range(shelves.size()):
			var shelf: TapButton = mounted.get_node("Shelf%d" % index) as TapButton
			assert_not_null(shelf, "Shelf%d" % index)
			assert_true(shelf.is_in_group(GeometryOracle.HIT_GROUP), "Shelf%d hit target" % index)
			assert_gte(shelf.get_global_rect().size.x, 120.0)
			assert_gte(shelf.get_global_rect().size.y, 120.0)
		mounted.queue_free()


func test_one_tap_buys_once_and_shows_the_sold_badge() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	assert_eq(scene.get_script(), STORE_SCRIPT)
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_coins", 20)
	var shelf_ids: Array[String] = scene.call("shelf_ids")
	var index: int = shelf_ids.find("mesa")
	assert_gte(index, 0, "mesa must be on a shelf")
	var price: int = FurnitureCatalog.price_of("mesa", scene.get("economy") as EconomyData)
	var coins_before: int = int(progress.call("get_coins"))

	var shelf: TapButton = scene.get_node("Shelf%d" % index) as TapButton
	for event: InputEvent in TouchSim.tap_events(shelf, true):
		shelf._gui_input(event)
	_settle()

	assert_eq(int(progress.call("get_coins")), coins_before - price, "one tap, one debit")
	assert_true(progress.call("owns_furniture", "mesa"))
	var badge: Control = scene.get_node("Shelf%d/SoldBadge%d" % [index, index]) as Control
	assert_true(badge.visible, "the sold badge marks what she already owns")
	assert_true(str(scene.get("fsm").state) == StoreScene.STATE_IDLE)


func test_a_second_tap_on_an_owned_piece_costs_nothing() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_coins", 20)
	assert_true(bool(scene.call("try_buy", "tapete")))
	var coins_after_first: int = int(progress.call("get_coins"))
	assert_false(bool(scene.call("try_buy", "tapete")))
	assert_eq(int(progress.call("get_coins")), coins_after_first)


func test_a_poor_tap_changes_nothing_and_is_counted() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_coins", 1)
	assert_false(bool(scene.call("try_buy", "cama")), "9 coins for a 10-coin bed from 1 coin")
	assert_eq(int(progress.call("get_coins")), 1, "no partial debit")
	assert_false(progress.call("owns_furniture", "cama"))
	assert_eq(int(scene.get("denials")), 1, "the miss is observable")


func test_home_returns_to_the_casa() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(2)
	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	var home: TapButton = scene.get_node("HomeButton") as TapButton
	for event: InputEvent in TouchSim.tap_events(home, true):
		home._gui_input(event)
	assert_eq(requested, ["res://scenes/casa.tscn"], "home, once")


func _settle() -> void:
	while str(scene.get("fsm").state) != StoreScene.STATE_IDLE:
		scene.call("advance", 0.05)
