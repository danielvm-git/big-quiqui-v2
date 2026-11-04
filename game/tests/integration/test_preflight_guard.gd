# story: e01s01
extends GutTest
## SC-E01-P0-08 — the anti-vacuity control.
##
## Two independent ways a "green" suite can lie:
##   1. the suite is empty (nothing is discovered, everything passes)
##   2. the guard that should notice (1) loses its teeth in a refactor
##
## This test watches both. The full negative path was exercised for real when the
## GUT class cache was missing on a fresh clone: GUT exited 0 having run nothing,
## and `scripts/preflight.sh` now fails on that instead of passing.

const PREFLIGHT_RELATIVE: String = "../scripts/preflight.sh"


func test_the_suite_is_not_empty() -> void:
	var discovered: int = _count_test_scripts("res://tests")
	assert_gt(discovered, 0, "0 discovered test scripts is a hard failure, not a green run")


func test_preflight_still_refuses_an_empty_suite() -> void:
	var source: String = _read_preflight()
	assert_ne(source, "", "scripts/preflight.sh must be readable")
	assert_true(
		source.contains("Nothing was run"),
		"the Zero-Test Guard must keep its zero-script verdict",
	)


func test_preflight_requires_positive_proof_the_suite_ran() -> void:
	var source: String = _read_preflight()
	assert_true(
		source.contains("no recognizable summary"),
		"a GUT run that prints nothing must fail the gate, not pass it",
	)


func test_preflight_imports_the_project_before_gut() -> void:
	var source: String = _read_preflight()
	var import_at: int = source.find("--import")
	var gut_at: int = source.find("gut_cmdln.gd")
	assert_gt(import_at, -1, "preflight must import the project (class cache is gitignored)")
	assert_gt(gut_at, -1, "preflight must run GUT")
	assert_true(import_at < gut_at, "the import must happen before GUT resolves class_names")


func _count_test_scripts(path: String) -> int:
	var total: int = 0
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var full: String = path.path_join(entry)
			if dir.current_is_dir():
				total += _count_test_scripts(full)
			elif entry.begins_with("test_") and entry.ends_with(".gd"):
				total += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return total


func _read_preflight() -> String:
	var project_root: String = ProjectSettings.globalize_path("res://")
	var absolute: String = project_root.path_join("..").path_join("scripts").path_join("preflight.sh")
	if not FileAccess.file_exists(absolute):
		absolute = project_root.path_join(PREFLIGHT_RELATIVE)
	return FileAccess.get_file_as_string(absolute)
