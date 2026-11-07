# story: e11s04
extends GutTest
## SC-E11-P0-04 — iOS preset excludes test trees and ships required application keys.


func test_ios_preset_excludes_test_trees_and_has_bundle_metadata() -> void:
	var path: String = ProjectSettings.globalize_path("res://export_presets.cfg")
	assert_true(FileAccess.file_exists(path))
	var text: String = FileAccess.get_file_as_string(path)
	assert_true(text.contains('name="iOS"'))
	assert_true(text.contains("application/bundle_identifier="))
	assert_true(text.contains("application/min_ios_version="))
	assert_true(text.contains("application/targeted_device_family="))
	assert_true(text.contains("res://tests/"))
	assert_true(text.contains("res://addons/gut/"))
