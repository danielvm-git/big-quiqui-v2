# story: e11s01
extends GutTest
## INV-03 — a refused mutation is invisible; a successful one writes exactly once.
##
## BUG-007/018/038 lineage: the money paths. A refusal that still moves state is how a
## toddler charge happens, and a state that lives only in RAM is gone when iOS kills
## the app from the switcher (ADR-005).

var pm: Node = null


func before_each() -> void:
	TestReset.reset_all()
	pm = get_node("/root/ProgressManager")
	pm.set_test_mode(true)
	pm.reset()
	TestReset.delete_test_save()


func after_each() -> void:
	pm.set_test_mode(true)
	pm.reset()
	TestReset.delete_test_save()
	pm.set_test_mode(false)


func _snapshot() -> String:
	return JSON.stringify((pm.data as SaveData).to_dictionary())


func _disk() -> String:
	if not FileAccess.file_exists(TestReset.TEST_SAVE_PATH):
		return ""
	return FileAccess.get_file_as_string(TestReset.TEST_SAVE_PATH)


func _assert_untouched(snapshot: String, writes: int, label: String) -> void:
	assert_eq(_snapshot(), snapshot, "%s: RAM moved on a refusal" % label)
	assert_eq(int(pm.write_count), writes, "%s: a refusal wrote to disk" % label)


func test_a_refused_purchase_leaves_ram_and_disk_untouched() -> void:
	pm.add_coins(2)
	var snapshot: String = _snapshot()
	var disk: String = _disk()
	var writes: int = int(pm.write_count)

	assert_false(pm.buy_furniture("cama", 10), "cannot afford it")
	assert_false(pm.buy_furniture("../../evil", 0), "invalid id")
	assert_false(pm.buy_furniture("cama", -5), "a negative price is not a gift")
	_assert_untouched(snapshot, writes, "buy")
	assert_eq(_disk(), disk, "the save file must be byte-identical after refusals")


func test_a_refused_placement_leaves_ram_and_disk_untouched() -> void:
	pm.add_coins(100)
	pm.buy_furniture("mesa", 1)
	var snapshot: String = _snapshot()
	var writes: int = int(pm.write_count)

	assert_false(pm.place_furniture("cama", 0.5, 0.5), "never bought")
	assert_false(pm.place_furniture("bad id", 0.5, 0.5))
	_assert_untouched(snapshot, writes, "place")


func test_a_refused_equip_leaves_ram_and_disk_untouched() -> void:
	var snapshot: String = _snapshot()
	var writes: int = int(pm.write_count)

	assert_false(pm.equip("body", "../../etc"))
	assert_false(pm.equip("", "vestido_flor"))
	_assert_untouched(snapshot, writes, "equip")


func test_a_successful_mutation_writes_exactly_once() -> void:
	var writes: int = int(pm.write_count)
	pm.add_coins(50)
	assert_eq(int(pm.write_count), writes + 1, "one logical change, one write")
	pm.buy_furniture("mesa", 4)
	assert_eq(int(pm.write_count), writes + 2)
	pm.place_furniture("mesa", 0.5, 0.5)
	assert_eq(int(pm.write_count), writes + 3)
	assert_gt(_disk().length(), 0, "the write reached the file")


func test_equipping_the_same_outfit_twice_is_not_a_second_write() -> void:
	assert_true(pm.equip("body", "vestido_flor"))
	var writes: int = int(pm.write_count)
	assert_true(pm.equip("body", "vestido_flor"), "idempotent, still true")
	assert_eq(int(pm.write_count), writes, "a no-op must not write")


func test_removing_an_absent_placement_is_a_refusal_not_an_error() -> void:
	var writes: int = int(pm.write_count)
	assert_false(pm.remove_furniture("mesa"))
	assert_eq(int(pm.write_count), writes)


func test_an_orphan_temp_file_never_becomes_the_save() -> void:
	pm.add_coins(7)
	pm.save()
	var file: FileAccess = FileAccess.open(pm.tmp_path(), FileAccess.WRITE)
	file.store_string('{"coins": 999999}')
	file.close()

	pm.data = SaveData.new()
	pm.load_or_default()
	assert_eq(pm.get_coins(), 7, "the .tmp is a corpse, not the save")
	assert_true(pm.has_orphan_tmp())
	pm.reset()
	assert_false(pm.has_orphan_tmp(), "reset clears the corpse")


func test_a_corrupt_save_degrades_to_defaults_and_names_the_reason() -> void:
	var file: FileAccess = FileAccess.open(TestReset.TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string("{ this is not json")
	file.close()

	pm.load_or_default()
	assert_eq(pm.last_error, "corrupt")
	assert_eq(pm.get_coins(), 0, "graceful degradation, never a crash")
	assert_not_null(pm.data, "the manager always owns a valid model")


func test_a_truncated_but_valid_json_object_still_loads() -> void:
	var file: FileAccess = FileAccess.open(TestReset.TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string('{"coins": 42}')
	file.close()

	pm.load_or_default()
	assert_eq(pm.last_error, "")
	assert_eq(pm.get_coins(), 42)


func test_a_save_written_by_an_older_version_still_loads() -> void:
	var file: FileAccess = FileAccess.open(TestReset.TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string('{"version": 0, "coins": 3, "tickets": 1}')
	file.close()

	pm.load_or_default()
	assert_eq(pm.get_coins(), 3, "a version the game never shipped is tolerated, not fatal")
	assert_gte(int((pm.data as SaveData).version), 1)


func test_placing_outside_the_room_clamps_instead_of_storing_garbage() -> void:
	pm.add_coins(100)
	pm.buy_furniture("mesa", 1)
	pm.place_furniture("mesa", -3.0, 9.0)
	var entry: Dictionary = pm.placed()[0]

	assert_eq(SaveCorpus.violations(pm.data), [] as Array[String], "the room is a 0..1 box")
	assert_almost_eq(float(entry["x"]), 0.0, 0.001)
	assert_almost_eq(float(entry["y"]), 1.0, 0.001)
