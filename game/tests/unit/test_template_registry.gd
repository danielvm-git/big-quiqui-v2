# story: e13s07
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


func _read(rel: String) -> String:
	var game_path: String = ProjectSettings.globalize_path("res://")
	var path: String = game_path.trim_suffix("/").get_base_dir().path_join(rel)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var body: String = file.get_as_text()
	file.close()
	return body
