# story: e13s07
# story: e13s09
extends GutTest
## The D3 skip is recorded. Neither guessed template is in the catalog.

const MANIFEST: String = "specs/product/TEMPLATE_USAGE_MANIFEST.json"


func test_the_skip_is_in_the_table_and_not_in_the_catalog() -> void:
	var table: String = _read("specs/product/TEMPLATE_TABLE.md")
	assert_true(table.contains("t22_play_beat"))
	assert_true(table.contains("t3_skip_beat"))
	assert_true(table.contains("| skip |"))
	var evidence: String = _read("specs/product/TEMPLATE_EVIDENCE_T22_T3.md")
	assert_true(evidence.contains("Confidence: low"), "SC-e13s06-P2-01 the evidence names its confidence")
	assert_true(evidence.contains("Call: skip"), "SC-e13s06-P2-01 and the call")
	var scope: String = _read("specs/product/SCOPE_LATEST.yaml")
	assert_true(scope.contains("59.5%"), "SC-e13s06-P2-02 the coverage sentence matches the call")
	assert_true(scope.contains("1,071"))
	var catalog: String = SourceScanner.text("res://scripts/core/template_catalog.gd")
	assert_false(catalog.contains("t22_play_beat"))
	assert_false(catalog.contains("t3_skip_beat"))


func test_the_computed_coverage_agrees_with_the_scope_and_the_catalog() -> void:
	var table: String = _read("specs/product/TEMPLATE_TABLE.md")
	var ids: Array = TemplateCatalog.SCRIPT_FOR_ID.keys()
	var bad: PackedStringArray = _gate(table, _read("specs/product/SCOPE_LATEST.yaml"), ids)
	assert_eq(bad, PackedStringArray(), "SC-e13s09-P1-03 SC-e13s09-P1-04: %s" % ", ".join(bad))
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
	var bad: PackedStringArray = _gate("\n".join(cut), _read("specs/product/SCOPE_LATEST.yaml"), ids)
	assert_gt(bad.size(), 0, "a catalog id with no row is a problem")
	assert_true(" ".join(bad).contains("t51_prize_pick"))


func test_a_scope_that_disagrees_fails_the_gate() -> void:
	var ids: Array = TemplateCatalog.SCRIPT_FOR_ID.keys()
	var scope: String = _read("specs/product/SCOPE_LATEST.yaml").replace(
		'scenes: 1071, share: "59.5%"', 'scenes: 1593, share: "88.4%"'
	)
	var bad: PackedStringArray = _gate(_read("specs/product/TEMPLATE_TABLE.md"), scope, ids)
	assert_gt(bad.size(), 0, "a claim the table does not back is a problem")


func test_a_row_that_names_a_def_without_its_template_fails_the_gate() -> void:
	var ids: Array = TemplateCatalog.SCRIPT_FOR_ID.keys()
	var table: String = _read("specs/product/TEMPLATE_TABLE.md").replace(
		"| t51_prize_pick | built | One tap saves one prize from the def. | item_ids | prize_probe |",
		"| t51_prize_pick | built | One tap saves one prize from the def. | item_ids | reward_probe |"
	)
	var bad: PackedStringArray = _gate(table, _read("specs/product/SCOPE_LATEST.yaml"), ids)
	assert_true(" ".join(bad).contains("has no t51_prize_pick step"))


func test_a_blank_cell_fails_the_gate_in_every_column() -> void:
	var ids: Array = TemplateCatalog.SCRIPT_FOR_ID.keys()
	for column: int in [
		TemplateTableGate.RULE,
		TemplateTableGate.PARAMETERS,
		TemplateTableGate.SCENE,
		TemplateTableGate.TEST,
		TemplateTableGate.EVIDENCE,
	]:
		var table: String = _blank(_read("specs/product/TEMPLATE_TABLE.md"), "t51_prize_pick", column)
		var bad: PackedStringArray = _gate(table, _read("specs/product/SCOPE_LATEST.yaml"), ids)
		var name: String = TemplateTableGate.COLUMNS[column]
		assert_true(" ".join(bad).contains("empty %s cell" % name), "B4 a blank %s is a problem" % name)


func test_a_duplicate_row_and_a_short_row_fail_the_gate() -> void:
	var ids: Array = TemplateCatalog.SCRIPT_FOR_ID.keys()
	var table: String = _read("specs/product/TEMPLATE_TABLE.md")
	var twice: String = (
		table + "| t51_prize_pick | built | again | item_ids | prize_probe | test_t51_prize_pick | 7 | e13s09 |\n"
	)
	var bad: PackedStringArray = _gate(twice, _read("specs/product/SCOPE_LATEST.yaml"), ids)
	assert_true(" ".join(bad).contains("t51_prize_pick has two rows"), "B4 duplicate rows")
	var short: String = table + "| t99_short | built | only a rule |\n"
	bad = _gate(short, _read("specs/product/SCOPE_LATEST.yaml"), ids)
	assert_true(" ".join(bad).contains("t99_short has 3 cells"), "B4 malformed rows")


func test_the_table_counts_come_from_the_manifest() -> void:
	var ids: Array = TemplateCatalog.SCRIPT_FOR_ID.keys()
	var scope: String = _read("specs/product/SCOPE_LATEST.yaml")
	var table: String = _read("specs/product/TEMPLATE_TABLE.md")
	var manifest: String = _read(MANIFEST)
	assert_true(manifest.contains('"sha256"'), "B7 the manifest carries its source hash")
	var edited: String = table.replace("test_t51_prize_pick | 7 |", "test_t51_prize_pick | 8 |")
	assert_ne(edited, table, "the injection changed the table")
	var bad: PackedStringArray = TemplateTableGate.problems(edited, scope, ids, manifest)
	assert_true(" ".join(bad).contains("the manifest measured 7"), "B7 a table count the source does not back fails")
	var both: String = scope.replace("scenes_using_a_template: 1801", "scenes_using_a_template: 1802")
	bad = TemplateTableGate.problems(table, both, ids, manifest)
	assert_true(" ".join(bad).contains("the manifest sums to 1801"), "B7 a scope total edited alone fails")
	bad = TemplateTableGate.problems(table, scope, ids, "")
	assert_true(" ".join(bad).contains("manifest is missing"), "B7 no manifest fails")


func _gate(table: String, scope: String, ids: Array) -> PackedStringArray:
	return TemplateTableGate.problems(table, scope, ids, _read(MANIFEST))


func _blank(table: String, id: String, column: int) -> String:
	var out: PackedStringArray = PackedStringArray()
	for line: String in table.split("\n"):
		if not line.begins_with("| %s " % id):
			out.append(line)
			continue
		var cells: PackedStringArray = TemplateTableGate.rows(line)[0]
		cells[column] = ""
		out.append("| " + " | ".join(cells) + " |")
	return "\n".join(out)


func _read(rel: String) -> String:
	var game_path: String = ProjectSettings.globalize_path("res://")
	var path: String = game_path.trim_suffix("/").get_base_dir().path_join(rel)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var body: String = file.get_as_text()
	file.close()
	return body
