# story: e11s04
extends GutTest
## SC-E11-P0-04 — iOS preset excludes tests and gut.


func test_ios_preset_excludes_test_trees() -> void:
	var path: String = ProjectSettings.globalize_path("res://export_presets.cfg")
	assert_true(FileAccess.file_exists(path))
	var text: String = FileAccess.get_file_as_string(path)
	assert_true(text.contains("res://tests/"))
	assert_true(text.contains("res://addons/gut/"))
	assert_true(text.contains('name="iOS"'))
