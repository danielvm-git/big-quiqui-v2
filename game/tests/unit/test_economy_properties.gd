# story: e08s04
extends GutTest
## SC-E08-P0-18..20 — economy never negative; wheel idempotent.


func before_each() -> void:
	TestReset.reset_all()


func test_balances_stay_non_negative_under_random_ops() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var progress: Node = get_node("/root/ProgressManager")
	for _i in range(40):
		var coins_op: int = rng.randi_range(-3, 5)
		var tickets_op: int = rng.randi_range(-2, 4)
		progress.call("add_coins", coins_op)
		progress.call("add_tickets", tickets_op)
		assert_gte(int(progress.call("get_coins")), 0)
		assert_gte(int(progress.call("get_tickets")), 0)


func test_complete_cycle_and_negative_clamp() -> void:
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("complete_cycle")
	assert_gte(int(progress.call("get_coins")), 0)
	assert_gte(int(progress.call("get_tickets")), 0)
	progress.call("add_coins", -9_999_999)
	progress.call("add_tickets", -9_999_999)
	assert_eq(int(progress.call("get_coins")), 0)
	assert_eq(int(progress.call("get_tickets")), 0)


## SC-E08-P0-20: cycle reward, recycle earn and wheel spends interleaved never go below zero, and a
## wheel with no tickets stays shut.
func test_cycle_recycle_and_wheel_interleave_stay_non_negative() -> void:
	var progress: Node = get_node("/root/ProgressManager")
	var packed: PackedScene = load("res://scenes/roda.tscn") as PackedScene
	var wheel: Control = packed.instantiate() as Control
	add_child_autofree(wheel)
	wheel.set("manual_step", true)
	await wait_process_frames(2)
	var spin: TapButton = wheel.get_node("SpinButton") as TapButton
	progress.call("complete_cycle")
	progress.call("add_coins", 1)
	var tickets_at_start: int = int(progress.call("get_tickets"))
	assert_gt(tickets_at_start, 0, "a finished cycle pays tickets")
	for _i in range(tickets_at_start + 3):
		for event: InputEvent in TouchSim.tap_events(spin, true):
			spin._gui_input(event)
		while str(wheel.get("fsm").state) != WheelScene.STATE_IDLE:
			wheel.call("advance", 0.05)
		assert_gte(int(progress.call("get_tickets")), 0)
		assert_gte(int(progress.call("get_coins")), 0)
	assert_eq(int(progress.call("get_tickets")), 0, "every ticket spent exactly once, none borrowed")
