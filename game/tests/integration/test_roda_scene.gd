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


func _tap(button: TapButton) -> void:
	for event: InputEvent in TouchSim.tap_events(button, true):
		button._gui_input(event)


func _settle() -> void:
	while str(scene.get("fsm").state) != WheelScene.STATE_IDLE:
		scene.call("advance", 0.05)


func _spin_many(count: int, seed_value: int) -> Array[int]:
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_tickets", count)
	scene.call("seed_rng", seed_value)
	var spin: TapButton = scene.get_node("SpinButton") as TapButton
	var payouts: Array[int] = []
	for _i in range(count):
		var before: int = int(progress.call("get_coins"))
		_tap(spin)
		_settle()
		payouts.append(int(progress.call("get_coins")) - before)
	return payouts


## BUG-037 / SC-E08-P1-15: the same seed replays, and a session is not one prize forever.
func test_seeded_spins_replay_and_vary() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var first: Array[int] = _spin_many(12, 1234)
	TestReset.reset_all()
	var second: Array[int] = _spin_many(12, 1234)
	assert_eq(first, second, "same seed -> same prizes")
	var distinct: Dictionary = {}
	for coins: int in first:
		distinct[coins] = true
	assert_gt(distinct.size(), 1, "twelve spins are not one constant prize")


## BUG-038: leaving mid-spin must not eat the ticket.
func test_home_is_inert_while_spinning() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_tickets", 1)
	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	_tap(scene.get_node("SpinButton") as TapButton)
	assert_eq(str(scene.get("fsm").state), WheelScene.STATE_SPINNING)
	_tap(scene.get_node("HomeButton") as TapButton)
	assert_eq(requested, [] as Array[String], "Home is ignored while the wheel turns")
	_settle()
	_tap(scene.get_node("HomeButton") as TapButton)
	assert_eq(requested, ["res://scenes/casa.tscn"] as Array[String], "Home works once idle")


## BUG-044: a hand-edited table cannot make spins free or mint tickets.
func test_zero_or_negative_cost_still_spends_one_ticket() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_tickets", 3)
	for cost: int in [0, -5]:
		var eco: EconomyData = EconomyData.new()
		eco.wheel_spin_ticket_cost = cost
		scene.call("apply_economy", eco)
		var before: int = int(progress.call("get_tickets"))
		_tap(scene.get_node("SpinButton") as TapButton)
		_settle()
		assert_eq(int(progress.call("get_tickets")), before - 1, "cost %d spends exactly one" % cost)


func test_no_ticket_means_no_spin() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	_tap(scene.get_node("SpinButton") as TapButton)
	assert_eq(str(scene.get("fsm").state), WheelScene.STATE_IDLE)
	assert_eq(int(get_node("/root/ProgressManager").call("get_coins")), 0)


## BUG-042: badge_hide is a transition, not a refresh side effect.
func test_badge_hide_is_logged_only_when_the_badge_actually_goes() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	scene.set("manual_step", true)
	await wait_process_frames(3)
	var progress: Node = get_node("/root/ProgressManager")
	var diary: Node = get_node("/root/Log")
	progress.call("add_coins", 1)
	assert_ne((diary.get("last_line") as Dictionary).get("ev"), "wheel.badge_hide", "no spin yet")
	progress.call("add_tickets", 1)
	_tap(scene.get_node("SpinButton") as TapButton)
	_settle()
	var seen: String = str((diary.get("last_line") as Dictionary).get("ev"))
	progress.call("add_coins", 1)
	assert_ne((diary.get("last_line") as Dictionary).get("ev"), "wheel.badge_hide", "not logged again")
	assert_ne(seen, "", "diary is open")
