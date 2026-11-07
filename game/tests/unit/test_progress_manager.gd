# story: e01s03
extends GutTest
## SC-E01-P1-04/05/06 — typed round-trip, atomic write, untrusted input.

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


func _seed() -> void:
	# Typed arrays: assigning an untyped literal to Array[String] / Array[Dictionary]
	# is a runtime error in Godot 4.7, not an implicit conversion.
	var outfits: Dictionary = {"body": "macacao_verde"}
	var furniture: Array[String] = ["tapete", "mesa"]
	var placed: Array[Dictionary] = [{"id": "mesa", "x": 0.25, "y": 0.75}]
	var stars: Dictionary = {"pato": 3}

	pm.data.coins = 42
	pm.data.tickets = 3
	pm.data.completed_cycles = 7
	pm.data.equipped_outfits = outfits
	pm.data.owned_furniture = furniture
	pm.data.placed_furniture = placed
	pm.data.friend_stars = stars


# SC-E01-P1-04
func test_round_trip_survives_a_ram_reset() -> void:
	_seed()
	assert_true(pm.save(), "save must succeed")

	pm.data = SaveData.new()  # RAM lost
	pm.load_or_default()

	assert_eq(pm.data.coins, 42)
	assert_eq(pm.data.tickets, 3)
	assert_eq(pm.data.completed_cycles, 7)
	assert_eq(pm.data.equipped_outfits, {"body": "macacao_verde"})
	assert_eq(pm.data.owned_furniture, ["tapete", "mesa"])
	assert_eq(pm.data.placed_furniture[0]["id"], "mesa")
	assert_almost_eq(float(pm.data.placed_furniture[0]["x"]), 0.25, 0.001)
	assert_eq(pm.data.friend_stars, {"pato": 3})


# SC-E01-P1-05
func test_atomic_write_leaves_no_tmp_file() -> void:
	_seed()
	assert_true(pm.save())

	assert_false(FileAccess.file_exists(pm.tmp_path()), "the .tmp must be renamed away")
	assert_true(FileAccess.file_exists(pm.save_path), "the real save exists")
	assert_false(pm.has_orphan_tmp())


# SC-E01-P1-05
func test_an_orphan_tmp_never_becomes_the_save() -> void:
	_seed()
	assert_true(pm.save())
	# Simulate a crash between "wrote tmp" and "renamed": a partial tmp is left behind.
	var tmp: FileAccess = FileAccess.open(pm.tmp_path(), FileAccess.WRITE)
	tmp.store_string('{"coins": 999999')
	tmp.close()

	pm.data = SaveData.new()
	pm.load_or_default()

	assert_eq(pm.data.coins, 42, "the intact save wins, the partial tmp is ignored")


# SC-E01-P1-06
func test_corrupt_save_recovers_to_defaults() -> void:
	var file: FileAccess = FileAccess.open(pm.save_path, FileAccess.WRITE)
	file.store_string("not json at all {{{")
	file.close()

	pm.load_or_default()

	assert_eq(pm.data.coins, 0, "a corrupt file yields defaults, never a crash")
	assert_eq(pm.last_error, "corrupt")


func test_negative_and_out_of_range_values_are_clamped() -> void:
	var raw: Dictionary = {
		"coins": -50,
		"tickets": 99_999_999,
		"completed_cycles": -3,
		"friend_stars": {"pato": 42},
	}
	var data: SaveData = SaveData.from_dictionary(raw)

	assert_eq(data.coins, 0)
	assert_eq(data.tickets, SaveData.MAX_TICKETS)
	assert_eq(data.completed_cycles, 0)
	assert_eq(data.friend_stars["pato"], SaveData.MAX_STARS)


func test_invalid_ids_are_dropped_not_loaded() -> void:
	var raw: Dictionary = {
		"owned_furniture": ["tapete", "Maria Clara", 42, "MESA", "mesa", "ok_item"],
		"equipped_outfits": {"body": "vestido_florido", "bad slot!": "x", "head": "../../etc"},
		"placed_furniture": [{"id": "ok_item", "x": 5.0, "y": -2.0}, {"id": "bad-id!", "x": 0.1}],
	}
	var data: SaveData = SaveData.from_dictionary(raw)

	assert_eq(data.owned_furniture, ["tapete", "mesa", "ok_item"])
	assert_eq(data.equipped_outfits, {"body": "vestido_florido"})
	assert_eq(data.placed_furniture.size(), 1)
	assert_almost_eq(float(data.placed_furniture[0]["x"]), 1.0, 0.001, "clamped into 0..1")
	assert_almost_eq(float(data.placed_furniture[0]["y"]), 0.0, 0.001)


func test_completing_a_cycle_pays_coins_tickets_and_counts() -> void:
	pm.complete_cycle()
	assert_eq(pm.data.coins, 5)
	assert_eq(pm.data.tickets, 1)
	assert_eq(pm.data.completed_cycles, 1)


func test_production_save_is_never_touched_in_test_mode() -> void:
	var production: String = pm.PRODUCTION_PATH
	var production_existed: bool = FileAccess.file_exists(production)

	_seed()
	pm.save()

	assert_eq(pm.save_path, pm.TEST_PATH)
	assert_false(FileAccess.file_exists(pm.tmp_path().replace(pm.TEST_PATH, production)))
	assert_eq(FileAccess.file_exists(production), production_existed)


func test_test_reset_wires_the_redirect() -> void:
	pm.set_test_mode(false)
	assert_eq(pm.save_path, pm.PRODUCTION_PATH)

	TestReset.reset_all()

	assert_true(pm.is_test_mode(), "TestReset must put ProgressManager in test mode")
	assert_eq(pm.save_path, pm.TEST_PATH)


# BUG-007: per-currency ceilings and one signal per logical change.
func test_tickets_use_their_own_ceiling() -> void:
	pm.add_tickets(9_999_999)

	assert_eq(pm.data.tickets, SaveData.MAX_TICKETS, "tickets are not coins")
	assert_lt(SaveData.MAX_TICKETS, SaveData.MAX_COINS, "the two ceilings are distinct on purpose")


func test_cycles_are_clamped() -> void:
	var raw: Dictionary = {"completed_cycles": 99_999_999}

	assert_eq(SaveData.from_dictionary(raw).completed_cycles, SaveData.MAX_CYCLES)


func test_complete_cycle_announces_once() -> void:
	var announced: Array[int] = []
	pm.progress_changed.connect(func() -> void: announced.append(1))

	pm.complete_cycle()

	assert_eq(announced.size(), 1, "one cycle, one signal — the HUD repaints once")
	assert_eq(pm.get_coins(), pm.CYCLE_COINS_REWARD)
	assert_eq(pm.get_tickets(), pm.CYCLE_TICKETS_REWARD)


# e05s01 / T-E05-01: the look survives a restart, and an id that cannot be a path
# never reaches disk.
func test_equipping_persists_and_round_trips_through_disk() -> void:
	pm.set_test_mode(true)
	pm.load_or_default()
	assert_true(pm.call("equip", SaveData.SLOT_BODY, "vestido_vermelho"))
	assert_true(pm.call("equip", SaveData.SLOT_HEAD, "coroa"))
	assert_eq(str(pm.call("equipped", SaveData.SLOT_HEAD)), "coroa")

	assert_true(pm.save())
	pm.reset()
	assert_eq(str(pm.call("equipped", SaveData.SLOT_BODY)), "", "reset clears memory")
	pm.load_or_default()
	assert_eq(str(pm.call("equipped", SaveData.SLOT_BODY)), "vestido_vermelho", "and disk brings it back")
	assert_eq(str(pm.call("equipped", SaveData.SLOT_HEAD)), "coroa")


func test_an_invalid_equip_is_refused() -> void:
	pm.set_test_mode(true)
	pm.load_or_default()
	for bad: String in ["../etc/passwd", "TIARA", "a".repeat(65)]:
		assert_false(pm.call("equip", SaveData.SLOT_HEAD, bad), bad)
		assert_false(pm.call("equip", "bad slot!", "coroa"), "slot must be an id too")
	assert_eq(pm.call("equipped", SaveData.SLOT_HEAD), "")


# e07 review (both reviewers): the reward must reach the disk, not only the RAM.
func test_completing_a_cycle_writes_the_save() -> void:
	pm.set_test_mode(true)
	pm.reset()
	var before: int = pm.write_count

	pm.complete_cycle()

	assert_eq(pm.write_count, before + 1, "exactly one write for the cycle")
	assert_true(FileAccess.file_exists(pm.save_path), "the save file exists")
	var coins_after: int = pm.get_coins()
	pm.data = SaveData.new()
	pm.load_or_default()
	assert_eq(pm.get_coins(), coins_after, "and a restart sees the reward")
