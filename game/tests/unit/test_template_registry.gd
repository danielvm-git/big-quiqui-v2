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


func test_the_computed_coverage_agrees_with_the_scope_and_the_catalog() -> void:
	var table: String = _read("specs/product/TEMPLATE_TABLE.md")
	var ids: Array = TemplateCatalog.SCRIPT_FOR_ID.keys()
	var bad: PackedStringArray = TemplateTableGate.problems(table, _read("specs/product/SCOPE_LATEST.yaml"), ids)
	assert_eq(bad, PackedStringArray(), "SC-e13s09-P1-03 P1-04: %s" % ", ".join(bad))
	var built: int = 0
	for cells: PackedStringArray in TemplateTableGate.rows(table):
		built += 1 if cells[TemplateTableGate.STATUS] == "built" else 0
	assert_eq(built, 11)
	assert_eq(TemplateTableGate.rows(table).size(), 13)


func test_a_missing_row_fails_the_gate() -> void:
	var ids: Array = TemplateCatalog.SCRIPT_FOR_ID.keys()
	var cut: PackedStringArray = PackedStringArray()
	for line: String in _read("specs/product/TEMPLATE_TABLE.md").split("\n"):
		if not line.begins_with("| t51_prize_pick"):
			cut.append(line)
	var bad: PackedStringArray = TemplateTableGate.problems(
		"\n".join(cut), _read("specs/product/SCOPE_LATEST.yaml"), ids
	)
	assert_gt(bad.size(), 0, "a catalog id with no row is a problem")
	assert_true(" ".join(bad).contains("t51_prize_pick"))


func test_a_scope_that_disagrees_fails_the_gate() -> void:
	var ids: Array = TemplateCatalog.SCRIPT_FOR_ID.keys()
	var scope: String = _read("specs/product/SCOPE_LATEST.yaml").replace(
		'scenes: 1071, share: "59.5%"', 'scenes: 1593, share: "88.4%"'
	)
	var bad: PackedStringArray = TemplateTableGate.problems(_read("specs/product/TEMPLATE_TABLE.md"), scope, ids)
	assert_gt(bad.size(), 0, "a claim the table does not back is a problem")


func test_a_row_that_names_a_def_without_its_template_fails_the_gate() -> void:
	var ids: Array = TemplateCatalog.SCRIPT_FOR_ID.keys()
	var table: String = _read("specs/product/TEMPLATE_TABLE.md").replace(
		"| t51_prize_pick | built | One tap saves one prize from the def. | item_ids | prize_probe |",
		"| t51_prize_pick | built | One tap saves one prize from the def. | item_ids | reward_probe |"
	)
	var bad: PackedStringArray = TemplateTableGate.problems(table, _read("specs/product/SCOPE_LATEST.yaml"), ids)
	assert_true(" ".join(bad).contains("has no t51_prize_pick step"))


func _read(rel: String) -> String:
	var game_path: String = ProjectSettings.globalize_path("res://")
	var path: String = game_path.trim_suffix("/").get_base_dir().path_join(rel)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var body: String = file.get_as_text()
	file.close()
	return body
