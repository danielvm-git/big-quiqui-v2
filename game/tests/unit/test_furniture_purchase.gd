# story: e09s01
extends GutTest
## SC-E09-P0-03/04 — `buy_furniture` is atomic, idempotent and never overdraws.

var pm: Node = null


func before_each() -> void:
	pm = get_node_or_null("/root/ProgressManager")
	assert_not_null(pm, "ProgressManager must be an autoload")
	pm.set_test_mode(true)
	pm.reset()
	TestReset.delete_test_save()


func after_each() -> void:
	pm.reset()
	TestReset.delete_test_save()
	pm.set_test_mode(false)


func test_a_purchase_debits_once_writes_once_and_survives_a_reload() -> void:
	pm.add_coins(10)
	var writes_before: int = pm.write_count
	assert_true(pm.buy_furniture("mesa", 4))
	assert_eq(pm.get_coins(), 6)
	assert_true(pm.owns_furniture("mesa"))
	assert_eq(pm.owned_count(), 1)
	assert_eq(pm.write_count, writes_before + 1, "one logical purchase is one atomic write")

	pm.data = SaveData.new()  # RAM lost, disk survives
	pm.load_or_default()
	assert_true(pm.owns_furniture("mesa"), "a purchase that lives only in RAM is gone on iOS")


func test_short_coins_change_nothing() -> void:
	pm.add_coins(2)
	var writes_before: int = pm.write_count
	assert_false(pm.buy_furniture("mesa", 4))
	assert_eq(pm.get_coins(), 2, "never overdraw")
	assert_false(pm.owns_furniture("mesa"))
	assert_eq(pm.owned_count(), 0)
	assert_eq(pm.write_count, writes_before, "a refused purchase writes nothing")


func test_buying_the_same_piece_twice_is_refused_and_free() -> void:
	pm.add_coins(10)
	assert_true(pm.buy_furniture("mesa", 4))
	var writes_before: int = pm.write_count
	assert_false(pm.buy_furniture("mesa", 4), "already owned")
	assert_eq(pm.get_coins(), 6, "the second tap must not charge again")
	assert_eq(pm.owned_count(), 1, "no duplicate entry")
	assert_eq(pm.write_count, writes_before)


func test_an_invalid_id_is_refused() -> void:
	pm.add_coins(10)
	for bad: String in ["", "../../etc/passwd", "Mesa", "x".repeat(65)]:
		assert_false(pm.buy_furniture(bad, 1), bad)
	assert_eq(pm.get_coins(), 10)
	assert_eq(pm.owned_count(), 0)


func test_a_negative_price_is_refused() -> void:
	pm.add_coins(5)
	assert_false(pm.buy_furniture("tapete", -3), "a negative price would mint coins")
	assert_eq(pm.get_coins(), 5)
	assert_false(pm.owns_furniture("tapete"))


func test_a_free_price_is_still_a_purchase() -> void:
	pm.add_coins(1)
	assert_true(pm.buy_furniture("tapete", 0), "a gift is owned, not auto-granted")
	assert_eq(pm.get_coins(), 1)
	assert_true(pm.owns_furniture("tapete"))
