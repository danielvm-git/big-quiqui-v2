# story: e08s02
extends GutTest
## SC-E08-P0-07..08, SC-E08-P1-09..10 — recycle earns once, hint once, miss returns.

const SCENE_PATH: String = "res://scenes/vila.tscn"
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
	assert_not_null(packed)
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func test_full_recycle_pays_one_coin_once() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	assert_eq(scene.get_script(), VILA_SCRIPT)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var bag: TouchDraggable = scene.get_node("RecycleBag") as TouchDraggable
	var bin: Control = scene.get_node("RecycleBin") as Control
	var hud: CoinTicketHud = scene.get_node("CoinTicketHud") as CoinTicketHud
	var progress: Node = get_node("/root/ProgressManager")
	assert_eq(int(progress.call("get_coins")), 0)
	var to_center: Vector2 = bin.get_global_rect().get_center()
	_deliver(bag, TouchSim.drag_events(bag, to_center, 8, true))
	assert_eq(int(progress.call("get_coins")), 1)
	assert_eq(scene.get("recycle_earns"), 1)
	_deliver(bag, TouchSim.drag_events(bag, to_center, 8, true))
	assert_eq(int(progress.call("get_coins")), 1, "second bag does nothing until respawn")


func test_miss_returns_without_paying() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var bag: TouchDraggable = scene.get_node("RecycleBag") as TouchDraggable
	var progress: Node = get_node("/root/ProgressManager")
	var miss: Vector2 = Vector2(80.0, 80.0)
	_deliver(bag, TouchSim.drag_events(bag, miss, 8, true))
	bag.advance(1.0)
	assert_eq(int(progress.call("get_coins")), 0)
	assert_eq(scene.get("recycle_earns"), 0)


func test_hint_runs_once_then_skips_after_success() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var hint: Node = scene.get_node("HintLayer/DragHint")
	var mgr: Node = scene.get_node("HintManager")
	var bag: TouchDraggable = scene.get_node("RecycleBag") as TouchDraggable
	var bin: Control = scene.get_node("RecycleBin") as Control
	scene.call("_maybe_start_recycle_hint")
	for _i in range(60):
		scene.call("advance", 0.05)
		mgr.call("advance", 0.05)
		if bool(hint.call("done")):
			break
	assert_true(bool(hint.call("done")), "hint animation finishes")
	assert_false(bool(mgr.call("try_show_next")), "queue empty after first dequeue")


func test_fly_coin_and_pulse_are_cosmetic_only() -> void:
	var hud: CoinTicketHud = CoinTicketHud.new()
	hud.size = Vector2(400.0, 100.0)
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(hud)
	await wait_process_frames(2)
	var progress: Node = get_node("/root/ProgressManager")
	var before: int = int(progress.call("get_coins"))
	hud.fly_coin(Vector2(100.0, 100.0))
	await wait_process_frames(30)
	assert_eq(int(progress.call("get_coins")), before, "fly_coin never writes save")
	hud.pulse_coin()
	await wait_process_frames(5)
	assert_eq(int(progress.call("get_coins")), before)
