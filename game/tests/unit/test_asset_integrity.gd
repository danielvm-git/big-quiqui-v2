# story: e11s01
extends GutTest
## INV-07b — every `res://` path the game names resolves, and every texture decodes.
##
## BUG-013/054 lineage: a renamed or missing asset must be a red gate, not a silently
## invisible sprite. The player is offline and cannot re-download, so a broken path is a
## permanent hole in the game.

const CHECKED_SUFFIXES: Array[String] = [".gd", ".tscn", ".tres", ".png", ".jpg", ".ogg", ".json"]


func test_every_referenced_res_path_exists() -> void:
	var missing: Array[String] = []
	var checked: int = 0
	for path: String in SourceScanner.res_paths():
		if not _is_checkable(path):
			continue
		checked += 1
		if not ResourceLoader.exists(path):
			missing.append(path)
	assert_gt(checked, 50, "the scanner must resolve the real corpus, not a handful")
	assert_eq(missing, [] as Array[String], "referenced but missing")


func test_every_referenced_texture_decodes_and_has_pixels() -> void:
	var broken: Array[String] = []
	for path: String in SourceScanner.res_paths():
		if not (path.ends_with(".png") or path.ends_with(".jpg")):
			continue
		if not ResourceLoader.exists(path):
			continue
		var texture: Texture2D = load(path) as Texture2D
		if texture == null or texture.get_width() < 2 or texture.get_height() < 2:
			broken.append(path)
	assert_eq(broken, [] as Array[String], "a zero-byte or unreadable texture breaks the rig oracle")


func test_every_referenced_audio_stream_loads() -> void:
	var broken: Array[String] = []
	for path: String in SourceScanner.res_paths():
		if not path.ends_with(".ogg"):
			continue
		if not ResourceLoader.exists(path):
			continue
		if load(path) as AudioStream == null:
			broken.append(path)
	assert_eq(broken, [] as Array[String], "a stream that does not load is a silent room")


func test_the_furniture_catalog_points_at_real_resources() -> void:
	var missing: Array[String] = []
	for id: String in FurnitureCatalog.FURNITURE_IDS:
		var path: String = "%s%s.tres" % [FurnitureCatalog.FURNITURE_DIR, id]
		if not ResourceLoader.exists(path):
			missing.append(path)
	assert_eq(missing, [] as Array[String], "a priced piece with no data is a dead shelf slot")


func test_every_food_in_the_catalog_resolves() -> void:
	var missing: Array[String] = []
	for food: Variant in FoodCatalog.all():
		var art: String = str(food.art_path)
		if not art.is_empty() and not ResourceLoader.exists(art):
			missing.append(art)
	assert_eq(missing, [] as Array[String], "the kitchen cannot feed her with a missing sprite")


func _is_checkable(path: String) -> bool:
	for suffix: String in CHECKED_SUFFIXES:
		if path.ends_with(suffix):
			return true
	return false
