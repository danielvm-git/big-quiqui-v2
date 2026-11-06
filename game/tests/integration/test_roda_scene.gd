# story: e08s03
extends GutTest
## SC-E08-P0-12..14, SC-E08-P1-15..16

const SCENE_PATH: String = "res://scenes/roda.tscn"
const WHEEL_SCRIPT = preload("res://scripts/scenes/roda.gd")

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


func test_wheel_passes_oracle_on_both_aspects() -> void:
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var mounted: Control = _mount(size)
		await wait_process_frames(2)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), oracle.summary())
		var spin: TapButton = mounted.get_node("SpinButton") as TapButton
		var rect: Rect2 = spin.get_global_rect()
		assert_gte(rect.size.x, 120.0)
		assert_gte(rect.size.y, 120.0)
		mounted.queue_free()


func test_one_spin_spends_one_ticket_and_awards_seeded_coins() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	assert_eq(scene.get_script(), WHEEL_SCRIPT)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var eco: EconomyData = EconomyData.new()
	eco.wheel_prize_weights = {"prize_a": 1}
	eco.wheel_prize_coins = {"prize_a": 2}
	scene.call("apply_economy", eco)
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_tickets", 5)
	assert_eq(int(progress.call("get_tickets")), 5)
	var spin: TapButton = scene.get_node("SpinButton") as TapButton
	for event: InputEvent in TouchSim.tap_events(spin, true):
		spin._gui_input(event)
	while str(scene.get("fsm").state) != WheelScene.STATE_IDLE:
		scene.call("advance", 0.05)
	assert_eq(int(progress.call("get_tickets")), 4)
	assert_eq(int(progress.call("get_coins")), 2)


func test_double_tap_does_not_spend_twice() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_tickets", 2)
	var spin: TapButton = scene.get_node("SpinButton") as TapButton
	for event: InputEvent in TouchSim.tap_events(spin, true):
		spin._gui_input(event)
	for event: InputEvent in TouchSim.tap_events(spin, true):
		spin._gui_input(event)
	while str(scene.get("fsm").state) != WheelScene.STATE_IDLE:
		scene.call("advance", 0.05)
	assert_eq(int(progress.call("get_tickets")), 1)


func test_badge_hides_after_first_spin() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_tickets", 1)
	await wait_process_frames(1)
	var badge: Control = scene.get_node("WheelBadge") as Control
	assert_true(badge.visible)
	var spin: TapButton = scene.get_node("SpinButton") as TapButton
	for event: InputEvent in TouchSim.tap_events(spin, true):
		spin._gui_input(event)
	while str(scene.get("fsm").state) != WheelScene.STATE_IDLE:
		scene.call("advance", 0.05)
	assert_false(badge.visible)
