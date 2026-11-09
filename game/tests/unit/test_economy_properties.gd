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
	var step: StepDef = SceneDefLoader.load_by_id("wheel").steps[0] as StepDef
	var tray: Control = Control.new()
	tray.size = Vector2(800.0, 160.0)
	add_child_autofree(tray)
	var tpl: RefCounted = TemplateCatalog.instantiate("t51_prize_pick")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	tpl.call("setup", ctx)
	progress.call("complete_cycle")
	progress.call("add_coins", 1)
	var tickets_at_start: int = int(progress.call("get_tickets"))
	assert_gt(tickets_at_start, 0, "a finished cycle pays tickets")
	for _i in range(tickets_at_start + 3):
		tpl.call("pick", "a")
		assert_gte(int(progress.call("get_tickets")), 0)
		assert_gte(int(progress.call("get_coins")), 0)
	assert_eq(int(progress.call("get_tickets")), 0, "every ticket spent exactly once, none borrowed")
