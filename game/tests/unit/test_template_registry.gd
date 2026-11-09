# story: e13s07
# story: e13s09
extends GutTest
## The D3 skip is recorded. Neither guessed template is in the catalog.


func test_the_skip_is_in_the_table_and_not_in_the_catalog() -> void:
	var table: String = _read("specs/product/TEMPLATE_TABLE.md")
	assert_true(table.contains("t22_play_beat"))
	assert_true(table.contains("t3_skip_beat"))
	assert_true(table.contains("| skip |"))
	var evidence: String = _read("specs/product/TEMPLATE_EVIDENCE_T22_T3.md")
	assert_true(evidence.contains("Confidence: low"))
	assert_true(evidence.contains("Call: skip"))
	var scope: String = _read("specs/product/SCOPE_LATEST.yaml")
	assert_true(scope.contains("59.5%"), "coverage sentence")
	assert_true(scope.contains("1,071"))
	var catalog: String = SourceScanner.text("res://scripts/core/template_catalog.gd")
	assert_false(catalog.contains("t22_play_beat"))
	assert_false(catalog.contains("t3_skip_beat"))


func test_the_table_covers_eleven_built_templates() -> void:
	var built: int = 0
	for line: String in _rows():
		if _built(line):
			built += 1
			_assert_consumer(line)
	assert_eq(built, 11, "SC-e13s09-P1-03")
	assert_eq(_rows().size(), 13)
	var share: String = "%.1f%%" % (100.0 * 1071.0 / 1801.0)
	assert_eq(share, "59.5%", "SC-e13s09-P1-04")
	assert_true(_read("specs/product/SCOPE_LATEST.yaml").contains("1,071"))


func _rows() -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	for line: String in _read("specs/product/TEMPLATE_TABLE.md").split("\n"):
		if line.begins_with("| t"):
			found.append(line)
	return found


func _built(line: String) -> bool:
	var cells: PackedStringArray = line.split("|")
	return cells.size() > 3 and cells[2].strip_edges() == "built"


func _assert_consumer(line: String) -> void:
	var cells: PackedStringArray = line.split("|")
	var id: String = cells[1].strip_edges()
	var scene_id: String = cells[5].strip_edges()
	var test_name: String = cells[6].strip_edges()
	assert_true(ResourceLoader.exists("res://scripts/templates/%s.gd" % id), id)
	assert_true(ResourceLoader.exists("res://data/scenes/%s.tres" % scene_id), scene_id)
	assert_true(ResourceLoader.exists("res://tests/unit/%s.gd" % test_name), test_name)


func _read(rel: String) -> String:
	var game_path: String = ProjectSettings.globalize_path("res://")
	var path: String = game_path.trim_suffix("/").get_base_dir().path_join(rel)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var body: String = file.get_as_text()
	file.close()
	return body
