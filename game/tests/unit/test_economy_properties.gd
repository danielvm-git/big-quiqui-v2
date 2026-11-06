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
