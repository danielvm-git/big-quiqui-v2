# story: e11s01
extends GutTest
## INV-01/INV-02 — `SaveData.from_dictionary` is total, bounded and idempotent.
##
## BUG-007/008/048 lineage: the save loader is the only place an untrusted file
## becomes game state, and every past data-integrity defect lived here.


func test_every_corpus_entry_loads_into_a_clean_save() -> void:
	var index: int = 0
	for entry: Dictionary in SaveCorpus.entries():
		var data: SaveData = SaveData.from_dictionary(entry)
		assert_not_null(data, "entry %d produced no save" % index)
		assert_eq(SaveCorpus.violations(data), [] as Array[String], "entry %d: %s" % [index, str(entry)])
		index += 1
	assert_gt(index, 20, "the corpus must stay adversarial, not shrink")


func test_a_loaded_save_round_trips_byte_for_byte() -> void:
	for entry: Dictionary in SaveCorpus.entries():
		var once: SaveData = SaveData.from_dictionary(entry)
		var twice: SaveData = SaveData.from_dictionary(once.to_dictionary())
		assert_eq(twice.to_dictionary(), once.to_dictionary(), "normalising twice != once")


func test_unknown_keys_never_reach_disk() -> void:
	var loaded: SaveData = SaveData.from_dictionary({"cheat": true, "coins": 5, "extra": [1, 2]})
	assert_false(loaded.to_dictionary().has("cheat"))
	assert_false(loaded.to_dictionary().has("extra"))
	assert_eq(loaded.coins, 5, "a known key next to junk still loads")


func test_absurd_magnitudes_saturate_instead_of_overflowing() -> void:
	var loaded: SaveData = SaveData.from_dictionary({"coins": SaveCorpus.ABSURD, "tickets": -SaveCorpus.ABSURD})
	assert_eq(loaded.coins, SaveData.MAX_COINS)
	assert_eq(loaded.tickets, 0)


func test_a_placement_the_child_never_bought_is_dropped() -> void:
	var raw: Dictionary = {
		"owned_furniture": ["mesa"],
		"placed_furniture":
		[
			{"id": "mesa", "x": 0.5, "y": 0.5},
			{"id": "cama", "x": 0.5, "y": 0.5},
			{"id": "sofa", "x": 0.5, "y": 0.5},
		],
	}
	var loaded: SaveData = SaveData.from_dictionary(raw)

	assert_eq(loaded.placed_furniture.size(), 1, "an unowned piece cannot stand in the room")
	assert_eq(str(loaded.placed_furniture[0]["id"]), "mesa")


func test_placements_survive_at_full_precision_inside_the_room() -> void:
	var loaded: SaveData = SaveData.from_dictionary(
		{"owned_furniture": ["mesa"], "placed_furniture": [{"id": "mesa", "x": 0.1234, "y": 0.9876}]}
	)
	var entry: Dictionary = loaded.placed_furniture[0]
	assert_almost_eq(float(entry["x"]), 0.1234, 0.0001, "a ratio must not be rounded into the wrong spot")
	assert_almost_eq(float(entry["y"]), 0.9876, 0.0001)


func test_random_dictionaries_never_break_the_invariants() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261107
	for step: int in range(200):
		var raw: Dictionary = SaveCorpus.random_entry(rng)
		var data: SaveData = SaveData.from_dictionary(raw)
		assert_eq(SaveCorpus.violations(data), [] as Array[String], "step %d: %s" % [step, str(raw)])


func test_clamp_to_rules_repairs_an_in_memory_save() -> void:
	var data: SaveData = SaveData.new()
	data.coins = -40
	data.owned_furniture = ["mesa", "mesa"]
	data.placed_furniture = [{"id": "cama", "x": 4.0, "y": -1.0}]
	data.clamp_to_rules()

	assert_eq(SaveCorpus.violations(data), [] as Array[String], "clamp is the RAM-side twin of the loader")
