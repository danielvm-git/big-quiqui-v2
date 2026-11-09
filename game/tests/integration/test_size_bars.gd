# story: e11s03
extends GutTest
## §5 — the size bars, as a gate instead of a review habit.
##
## CONVENTIONS §5 has said "one file, one subject: 300 lines maximum" since the e07 post-epic
## review, and every audit quotes it, but nothing failed when a file crossed it: the e09
## review missed a 349-line test and the e10/e11 landing pushed `progress_manager.gd` to 341
## and `ci-cd.yml` from 341 to 348 without a single red stage. A rule the machine does not
## check is a rule that drifts.
##
## The ceilings below are the grandfathered debt, pinned at its size on 2026-11-07. A file in
## the map may shrink freely and may not grow by one line; a file outside it may not cross 300.

const MAX_LINES: int = 300
const SCAN_ROOTS: Array[String] = ["res://scripts", "res://tools", "res://tests"]
const GRANDFATHERED: Dictionary = {
	"res://scripts/components/quiqui_rig.gd": 427,
	"res://tests/unit/test_quiqui_rig.gd": 404,
	"res://scripts/components/touch_draggable.gd": 326,
}


func test_no_new_file_crosses_the_three_hundred_line_bar() -> void:
	var offenders: Array[String] = []
	for path: String in _scripts():
		if GRANDFATHERED.has(path):
			continue
		var lines: int = _lines(path)
		if lines > MAX_LINES:
			offenders.append("%s: %d lines" % [path, lines])
	assert_eq(offenders, [] as Array[String], "split by subject (CONVENTIONS §5)")


func test_no_grandfathered_file_grows() -> void:
	var offenders: Array[String] = []
	for path: String in GRANDFATHERED.keys():
		var ceiling: int = int(GRANDFATHERED[path])
		var lines: int = _lines(path)
		if lines > ceiling:
			offenders.append("%s: %d > %d" % [path, lines, ceiling])
	assert_eq(offenders, [] as Array[String], "growing grandfathered debt is a violation")


func test_a_grandfathered_file_may_shrink_and_the_map_must_follow() -> void:
	## Debt that is paid off has to leave the map, otherwise the next pass "grandfathers" a
	## file that is already clean and the number stops meaning anything.
	var stale: Array[String] = []
	for path: String in GRANDFATHERED.keys():
		var lines: int = _lines(path)
		if lines <= MAX_LINES:
			stale.append("%s is %d lines — remove it from the map" % [path, lines])
	assert_eq(stale, [] as Array[String], "shrink it, then delete its allowance")


func test_the_scan_actually_sees_the_project() -> void:
	assert_gte(_scripts().size(), 150, "a gate that scans nothing passes everything")


func _scripts() -> Array[String]:
	var found: Array[String] = []
	for root: String in SCAN_ROOTS:
		found.append_array(_walk(root))
	found.sort()
	return found


func _walk(path: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		var child: String = "%s/%s" % [path, name]
		if dir.current_is_dir():
			if not name.begins_with("."):
				found.append_array(_walk(child))
		elif name.ends_with(".gd"):
			found.append(child)
		name = dir.get_next()
	dir.list_dir_end()
	return found


func _lines(path: String) -> int:
	if not FileAccess.file_exists(path):
		return -1
	var body: String = FileAccess.get_file_as_string(path)
	# `wc -l` semantics: a trailing newline ends the last line, it does not open a new one.
	var parts: PackedStringArray = body.split("\n")
	return parts.size() - (1 if body.ends_with("\n") else 0)
