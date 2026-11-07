# story: e09s04
extends GutTest
## SC-E09-P0-04 — one save, one walk: buy in the store, place in the casinha, re-mount on
## the other canvas, and the party is still locked at two pieces. Every action writes
## exactly one diary event, echo or no echo.

const MERCADO: String = "res://scenes/mercado.tscn"
const CASINHA: String = "res://scenes/casinha.tscn"
const FESTA: String = "res://scenes/festa.tscn"

var scene: Control = null
## The diary is one file per session and every test shares it, so each assertion is a
## delta from the count this test started with.
var baseline: Dictionary = {}


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()
	baseline = {"store.buy": _count_events("store.buy"), "casinha.place": _count_events("casinha.place")}


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _mount(path: String, size: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var instance: Node = (load(path) as PackedScene).instantiate()
	viewport.add_child(instance)
	return instance as Control


func _dismiss() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _area() -> Rect2:
	return (scene.get_node("PlacementArea") as Control).get_global_rect()


func _drag_to_ratio(id: String, ratio: Vector2) -> void:
	var prop: Control = scene.get_node("Prop_" + id) as Control
	var area: Rect2 = _area()
	var target: Vector2 = area.position + area.size * ratio
	for event: InputEvent in TouchSim.drag_events(prop, target, 8, true):
		prop._gui_input(TouchSim.gui_event(prop, event))


func test_the_epic_walk_buy_place_redraw_and_the_party_stays_shut() -> void:
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_coins", 50)
	await _buy_two_pieces()
	await _place_two_pieces()
	var saved: Array[Dictionary] = await _assert_room_survives_the_other_canvas()
	await _assert_party_still_locked(saved)


func _buy_two_pieces() -> void:
	scene = _mount(MERCADO, GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	assert_true(bool(scene.call("try_buy", "mesa")), "the store sells mesa")
	_settle_store()
	assert_true(bool(scene.call("try_buy", "tapete")), "the store sells tapete")
	_settle_store()
	var progress: Node = get_node("/root/ProgressManager")
	assert_eq(50 - int(progress.call("get_coins")), 4 + 2, "exactly the two prices, no more")
	assert_eq(_delta("store.buy"), 2, "one event per purchase")
	_dismiss()


func _place_two_pieces() -> void:
	scene = _mount(CASINHA, GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	_drag_to_ratio("mesa", Vector2(0.30, 0.55))
	_drag_to_ratio("tapete", Vector2(0.70, 0.70))
	var progress: Node = get_node("/root/ProgressManager")
	assert_eq(int(progress.call("placed_count")), 2, "both pieces stand in the room")
	assert_eq(_delta("casinha.place"), 2, "one event per placement")
	_dismiss()


func _assert_room_survives_the_other_canvas() -> Array[Dictionary]:
	var saved: Array[Dictionary] = get_node("/root/ProgressManager").call("placed") as Array[Dictionary]
	scene = _mount(CASINHA, GeometryOracle.IPAD_4_3)
	await wait_process_frames(3)
	var oracle: PlacementOracle = PlacementOracle.new()
	assert_true(
		oracle.audit_normalized(GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3, saved, scene).is_empty(),
		oracle.summary(),
	)
	_dismiss()
	return saved


func _assert_party_still_locked(saved: Array[Dictionary]) -> void:
	assert_eq(saved.size(), 2, "two pieces, no more")
	scene = _mount(FESTA, GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(3)
	assert_eq(str(scene.get("fsm").state), HousePartyScene.STATE_LOCKED, "two is not five")
	assert_false(bool(scene.call("party_unlocked")))


## One purchase at a time: the store only takes a new tap from IDLE.
func _settle_store() -> void:
	var guard: int = 0
	while scene != null and str(scene.get("fsm").state) != StoreScene.STATE_IDLE and guard < 200:
		scene.call("advance", 0.05)
		guard += 1
	assert_lt(guard, 200, "the store returned to IDLE")


## The diary is the one observable that catches a doubled handler: a purchase that fires
## twice writes two `store.buy` lines even when the coins look right.
func _delta(ev_id: String) -> int:
	return _count_events(ev_id) - int(baseline.get(ev_id, 0))


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
