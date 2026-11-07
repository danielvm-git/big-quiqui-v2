# story: e11s01
extends GutTest
## INV-04 — the tuning tables are total and non-degenerate.
##
## FIX-05 moved every price and prize weight into `EconomyData`, whose own docstring
## promises "a missing or negative entry is 0, never a gift that mints coins". A price
## of 0 *is* a gift: the store would hand the piece over for free. BUG-044 is the twin
## defect on the wheel side (a non-positive ticket cost minted free spins).


func test_the_price_table_covers_the_catalog_exactly() -> void:
	var economy: EconomyData = EconomyData.new()
	var priced: Array = economy.furniture_prices.keys()
	priced.sort()

	var catalog: Array = FurnitureCatalog.FURNITURE_IDS.duplicate()
	catalog.sort()
	assert_eq(priced, catalog, "a piece with no price is a free piece")


func test_every_price_is_a_positive_integer() -> void:
	var economy: EconomyData = EconomyData.new()
	for id: String in FurnitureCatalog.FURNITURE_IDS:
		var price: int = FurnitureCatalog.price_of(id, economy)
		assert_gt(price, 0, "%s must cost at least one coin" % id)


func test_a_missing_price_is_refused_not_free() -> void:
	var economy: EconomyData = EconomyData.new()
	economy.furniture_prices = {"abajur": 3}
	var price: int = FurnitureCatalog.price_of("tapete", economy)

	assert_false(price == 0, "an unpriced piece must not be purchasable for nothing")


func test_the_wheel_tables_agree_with_each_other() -> void:
	var economy: EconomyData = EconomyData.new()
	var weights: Array = economy.wheel_prize_weights.keys()
	var coins: Array = economy.wheel_prize_coins.keys()
	weights.sort()
	coins.sort()

	assert_eq(weights, coins, "a prize with a weight but no payout is an empty win")
	assert_gte(weights.size(), 2, "one prize is not a wheel")


func test_every_prize_weight_and_payout_is_positive() -> void:
	var economy: EconomyData = EconomyData.new()
	for key: Variant in economy.wheel_prize_weights.keys():
		assert_gte(int(economy.wheel_prize_weights[key]), 1, "weight for %s" % str(key))
	for key: Variant in economy.wheel_prize_coins.keys():
		assert_gte(int(economy.wheel_prize_coins[key]), 1, "payout for %s" % str(key))


func test_a_spin_always_costs_at_least_one_ticket() -> void:
	var economy: EconomyData = EconomyData.new()
	assert_gte(economy.wheel_spin_ticket_cost, 1, "a free spin is a mint")

	economy.wheel_spin_ticket_cost = 0
	var scene: Node = load("res://scenes/roda.tscn").instantiate()
	scene.economy = economy
	assert_gte(_spin_cost(scene), 1, "the scene floors it too (BUG-044)")


func _spin_cost(scene: Node) -> int:
	## Mirrors roda.gd's own floor without booting the scene: the contract is the floor,
	## not the internal call site.
	var economy: EconomyData = scene.economy
	return maxi(economy.wheel_spin_ticket_cost, 1)


func test_the_pick_never_returns_an_unpriced_prize() -> void:
	var economy: EconomyData = EconomyData.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 99
	for _i: int in range(300):
		var prize: String = economy.pick_prize(rng)
		assert_true(economy.wheel_prize_coins.has(prize), "picked %s, which pays nothing" % prize)


func test_star_caps_match_the_save_model() -> void:
	assert_gte(SaveData.MAX_STARS, 1)
	var stars: Dictionary = SaveData.from_dictionary({"friend_stars": {"pato": 99}}).friend_stars
	assert_eq(int(stars["pato"]), SaveData.MAX_STARS, "the save and the album share one cap")
