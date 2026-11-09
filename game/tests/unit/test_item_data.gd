# story: e03s02
extends GutTest
## SC-E03-P0-07 catalog integrity, SC-E03-P1-10 seeded distinct tray,
## SC-E03-P1-11 bad data degrades with a diary line instead of a crash.

const ART_ROOT: String = "res://assets/art/items/"
const FOODS_DIR: String = "res://resources/foods/"
const SEED: int = 20261105


func before_each() -> void:
	TestReset.reset_all()


func test_the_catalog_has_exactly_ten_distinct_foods() -> void:
	var seen: Dictionary = {}
	for id: String in FoodCatalog.FOOD_IDS:
		assert_true(Ids.is_valid(id), "%s passes the id contract" % id)
		seen[id] = true

	assert_eq(FoodCatalog.FOOD_IDS.size(), 10)
	assert_eq(seen.size(), 10, "no id appears twice")
	assert_eq(_ids_of(FoodCatalog.all()), FoodCatalog.FOOD_IDS, "all() keeps the frozen order")


func test_every_resource_file_loads_as_item_data_with_its_own_id() -> void:
	for id: String in FoodCatalog.FOOD_IDS:
		var path: String = "%s%s.tres" % [FOODS_DIR, id]
		assert_true(ResourceLoader.exists(path), "%s exists" % path)
		var item: ItemData = load(path) as ItemData
		assert_not_null(item, "%s loads as ItemData" % path)
		if item != null:
			assert_eq(item.id, id, "%s names itself" % path)


func test_no_resource_file_exists_outside_the_catalog() -> void:
	var files: PackedStringArray = DirAccess.get_files_at(FOODS_DIR)
	var resources: Array[String] = []
	for file: String in files:
		if file.ends_with(".tres"):
			resources.append(file.trim_suffix(".tres"))
	resources.sort()
	var expected: Array[String] = FoodCatalog.FOOD_IDS.duplicate()
	expected.sort()

	assert_eq(resources, expected)


func test_every_food_has_real_art_under_the_items_folder() -> void:
	for item: ItemData in FoodCatalog.all():
		assert_eq(item.art_path, "%s%s.png" % [ART_ROOT, item.id], "%s art path" % item.id)
		assert_not_null(item.texture(), "%s art loads" % item.id)


func test_get_item_returns_the_named_food() -> void:
	var item: ItemData = FoodCatalog.get_item("watermelon")

	assert_not_null(item)
	if item != null:
		assert_eq(item.id, "watermelon")


func test_get_item_refuses_anything_outside_the_catalog() -> void:
	assert_null(FoodCatalog.get_item("nao_existe"), "unknown id")
	assert_null(FoodCatalog.get_item("ball"), "real art, but not a food")
	assert_null(FoodCatalog.get_item(""), "empty id")
	assert_null(FoodCatalog.get_item("../../project"), "path traversal")


func test_an_unknown_id_is_logged_without_echoing_it() -> void:
	FoodCatalog.get_item("Maria Clara")
	var line: Dictionary = _last_diary_line()

	assert_eq(line.get("ev", ""), "item.unknown")
	assert_eq(line.get("item", ""), "invalid", "untrusted text never reaches the diary")


func test_missing_data_file_returns_null_and_logs() -> void:
	assert_null(FoodCatalog.get_item("carrot", "res://resources/foods/missing/"))
	var line: Dictionary = _last_diary_line()

	assert_eq(line.get("ev", ""), "item.missing_data")
	assert_eq(line.get("item", ""), "carrot")


func test_a_tray_holds_the_requested_number_of_distinct_foods() -> void:
	for count: int in [1, 3, 10]:
		var ids: Array[String] = _ids_of(FoodCatalog.pick_tray(_rng(SEED), count))
		var seen: Dictionary = {}
		for id: String in ids:
			seen[id] = true
		assert_eq(ids.size(), count, "tray of %d" % count)
		assert_eq(seen.size(), count, "tray of %d has no repeats" % count)


func test_the_same_seed_gives_the_same_tray() -> void:
	var first: Array[String] = _ids_of(FoodCatalog.pick_tray(_rng(SEED), 3))
	var second: Array[String] = _ids_of(FoodCatalog.pick_tray(_rng(SEED), 3))

	assert_eq(first, second)


func test_the_seed_actually_drives_the_tray() -> void:
	var first: Array[String] = _ids_of(FoodCatalog.pick_tray(_rng(SEED), 10))
	var second: Array[String] = _ids_of(FoodCatalog.pick_tray(_rng(SEED + 1), 10))

	assert_ne(first, second, "another seed gives another order")
	assert_ne(first, FoodCatalog.FOOD_IDS, "the tray is not the catalog order")


func test_the_tray_size_is_clamped_at_both_ends() -> void:
	assert_eq(FoodCatalog.pick_tray(_rng(SEED), 99).size(), 10, "above the catalog")
	assert_eq(FoodCatalog.pick_tray(_rng(SEED), 0).size(), 0, "zero")
	assert_eq(FoodCatalog.pick_tray(_rng(SEED), -3).size(), 0, "negative")


func test_missing_art_returns_null_and_logs() -> void:
	var item: ItemData = _item("nao_existe", "%snao_existe.png" % ART_ROOT)

	assert_null(item.texture())
	var line: Dictionary = _last_diary_line()
	assert_eq(line.get("ev", ""), "item.missing_art")
	assert_eq(line.get("item", ""), "nao_existe")


func test_an_invalid_id_returns_null_even_with_real_art() -> void:
	var item: ItemData = _item("../Maria Clara", "%scarrot.png" % ART_ROOT)

	assert_null(item.texture())
	var line: Dictionary = _last_diary_line()
	assert_eq(line.get("ev", ""), "item.invalid_id")
	assert_eq(line.get("item", ""), "invalid", "untrusted text never reaches the diary")


func test_an_empty_item_degrades() -> void:
	assert_null(ItemData.new().texture())


func test_a_path_that_is_not_a_texture_degrades() -> void:
	var item: ItemData = _item("carrot", "%scarrot.tres" % FOODS_DIR)

	assert_null(item.texture())
	assert_eq(_last_diary_line().get("ev", ""), "item.missing_art")


func _item(id: String, art_path: String) -> ItemData:
	var item: ItemData = ItemData.new()
	item.id = id
	item.art_path = art_path
	return item


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _ids_of(items: Array[ItemData]) -> Array[String]:
	var ids: Array[String] = []
	for item: ItemData in items:
		ids.append(item.id)
	return ids


func _last_diary_line() -> Dictionary:
	var log_node: Node = get_node_or_null("/root/Log")
	assert_not_null(log_node, "Log autoload is registered")
	if log_node == null:
		return {}
	var file: FileAccess = FileAccess.open(str(log_node.get("log_path")), FileAccess.READ)
	if file == null:
		return {}
	var last: String = ""
	while not file.eof_reached():
		var line: String = file.get_line()
		if not line.strip_edges().is_empty():
			last = line
	file.close()
	var parsed: Variant = JSON.parse_string(last)
	return parsed as Dictionary if parsed is Dictionary else {}
