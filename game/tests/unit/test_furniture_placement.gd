# story: e09s02
extends GutTest
## SC-E09-P0-05/06 — placements are normalized, owned-only, and survive a reload.

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


func _own(id: String) -> void:
	pm.add_coins(100)
	assert_true(pm.buy_furniture(id, 1), id)


func test_a_placement_is_saved_normalized_and_reloads() -> void:
	_own("mesa")

	assert_true(pm.place_furniture("mesa", 0.25, 1.4), "out-of-range y is clamped, not refused")
	assert_eq(pm.placed_count(), 1)
	var saved: Array[Dictionary] = pm.placed()
	assert_almost_eq(float(saved[0]["x"]), 0.25, 0.001)
	assert_almost_eq(float(saved[0]["y"]), 1.0, 0.001, "clamped into the room")

	pm.data = SaveData.new()
	pm.load_or_default()
	assert_eq(pm.placed_count(), 1, "a placement that lives only in RAM is gone on iOS")


func test_placing_the_same_piece_twice_moves_it_instead_of_duplicating() -> void:
	_own("mesa")
	pm.place_furniture("mesa", 0.2, 0.2)
	pm.place_furniture("mesa", 0.8, 0.7)

	assert_eq(pm.placed_count(), 1, "one piece, one slot")
	var saved: Array[Dictionary] = pm.placed()
	assert_almost_eq(float(saved[0]["x"]), 0.8, 0.001)


func test_an_unowned_or_invalid_piece_cannot_be_placed() -> void:
	assert_false(pm.place_furniture("cama", 0.5, 0.5), "not bought, not placeable")
	assert_false(pm.place_furniture("../../etc", 0.5, 0.5))
	assert_false(pm.place_furniture("", 0.5, 0.5))
	assert_eq(pm.placed_count(), 0)


func test_remove_furniture_returns_the_piece_to_the_tray() -> void:
	_own("tapete")
	pm.place_furniture("tapete", 0.5, 0.5)

	assert_true(pm.remove_furniture("tapete"))
	assert_eq(pm.placed_count(), 0)
	assert_true(pm.owns_furniture("tapete"), "taking it out of the room keeps it")
	assert_false(pm.remove_furniture("tapete"), "removing what is not there changes nothing")


func test_a_tampered_save_cannot_place_outside_the_room() -> void:
	_own("sofa")
	var tampered: Array[Dictionary] = [
		{"id": "sofa", "x": 9.0, "y": -9.0},
		{"id": "../evil", "x": 0.5},
	]
	pm.data.placed_furniture = tampered
	pm.data.clamp_to_rules()

	assert_eq(pm.placed_count(), 1, "the invalid id is dropped")
	var saved: Array[Dictionary] = pm.placed()
	assert_almost_eq(float(saved[0]["x"]), 1.0, 0.001)
	assert_almost_eq(float(saved[0]["y"]), 0.0, 0.001)


func test_a_tampered_save_cannot_duplicate_placed_furniture() -> void:
	_own("sofa")
	var tampered: Array[Dictionary] = [
		{"id": "sofa", "x": 0.2, "y": 0.2},
		{"id": "sofa", "x": 0.8, "y": 0.8},
		{"id": "sofa", "x": 0.5, "y": 0.5},
	]
	pm.data.placed_furniture = tampered
	pm.data.clamp_to_rules()

	assert_eq(pm.placed_count(), 1, "duplicate placements for the same item must be dropped")
	var saved: Array[Dictionary] = pm.placed()
	assert_eq(saved.size(), 1)
	assert_almost_eq(float(saved[0]["x"]), 0.2, 0.001)
