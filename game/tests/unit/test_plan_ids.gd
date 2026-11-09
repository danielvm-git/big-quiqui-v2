# story: e13s09
extends GutTest
## Every live scenario in the e13 test plan is named, verbatim, in a test body. A plan row cannot drift
## away from its proof. A row marked `withdrawn` is the only one allowed to have no test.

const PLAN: String = "res://../specs/tech-architecture/e13-TEST_PLAN_LATEST.md"
const TESTS: String = "res://tests"
const ID_PATTERN: String = "^\\| (SC-e13s\\d\\d-P\\d-\\d\\d) \\|(.*)$"


func test_every_live_plan_id_appears_in_a_test_body() -> void:
	var missing: PackedStringArray = _missing(_plan_rows(), _test_text())
	assert_eq(missing, PackedStringArray(), "SC-e13s09 plan ids with no proof: %s" % ", ".join(missing))


func test_a_plan_id_with_no_test_body_is_found() -> void:
	var rows: Array[PackedStringArray] = [PackedStringArray(["SC-e13s99-P0-01", " live row"])]
	assert_eq(_missing(rows, "nothing names it"), PackedStringArray(["SC-e13s99-P0-01"]), "the check is not vacuous")
	assert_eq(_missing(rows, "SC-e13s99-P0-01 is here"), PackedStringArray())
	var withdrawn: Array[PackedStringArray] = [PackedStringArray(["SC-e13s99-P0-02", " withdrawn | x"])]
	assert_eq(_missing(withdrawn, ""), PackedStringArray(), "a withdrawn row needs no test")


func test_the_plan_has_rows() -> void:
	assert_gt(_plan_rows().size(), 40, "the plan was read")


func _missing(rows: Array[PackedStringArray], text: String) -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	for row: PackedStringArray in rows:
		if not row[1].strip_edges().begins_with("withdrawn") and not text.contains(row[0]):
			missing.append(row[0])
	return missing


func _plan_rows() -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var pattern: RegEx = RegEx.create_from_string(ID_PATTERN)
	var body: String = FileAccess.get_file_as_string(ProjectSettings.globalize_path(PLAN))
	for line: String in body.split("\n"):
		var found: RegExMatch = pattern.search(line)
		if found != null:
			rows.append(PackedStringArray([found.get_string(1), found.get_string(2)]))
	return rows


func _test_text() -> String:
	var text: String = ""
	for path: String in _gd_files(TESTS):
		if not path.ends_with("test_plan_ids.gd"):
			text += FileAccess.get_file_as_string(path)
	return text


func _gd_files(dir_path: String) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	for name: String in DirAccess.get_files_at(dir_path):
		if name.ends_with(".gd"):
			found.append("%s/%s" % [dir_path, name])
	for sub: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_gd_files("%s/%s" % [dir_path, sub]))
	return found
