# story: e11s01
extends GutTest
## INV-08 — a gate that cannot fail is not a gate (the e08 lesson, BUG-040).
##
## Every oracle below is driven with a deliberately broken input. If one of them reports
## clean, the suite is decorative: the per-scene tests that use it would pass on a broken
## game just as happily.

const TEMP_ROOT: String = "user://gate_can_fail"


func before_each() -> void:
	_remove_tree(TEMP_ROOT)


func after_each() -> void:
	_remove_tree(TEMP_ROOT)


func test_the_geometry_oracle_rejects_a_letterboxed_background() -> void:
	var stage: Control = _stage(Vector2(400.0, 300.0))
	var findings: Array[String] = GeometryOracle.new().audit(stage, GeometryOracle.DESKTOP_16_9)
	assert_gt(findings.size(), 0, "a background smaller than the canvas is letterbox bars")


func test_the_geometry_oracle_rejects_a_target_a_child_cannot_hit() -> void:
	var stage: Control = _stage(GeometryOracle.DESKTOP_16_9)
	var button: Button = Button.new()
	button.name = "Tiny"
	button.size = Vector2(60.0, 60.0)
	button.position = Vector2(100.0, 100.0)
	button.add_to_group(GeometryOracle.HIT_GROUP, false)
	stage.add_child(button)

	var findings: Array[String] = GeometryOracle.new().audit(stage, GeometryOracle.DESKTOP_16_9)
	assert_gt(findings.size(), 0, "60x60 is below the 120x120 floor for ages 4-7")


func test_the_placement_oracle_fails_closed_on_an_empty_save() -> void:
	var oracle: PlacementOracle = PlacementOracle.new()
	var findings: Array[String] = oracle.audit_normalized(
		GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3, [], Control.new()
	)
	assert_gt(findings.size(), 0, "nothing placed proves nothing — silence is not a pass")


func test_the_scene_oracle_rejects_a_missing_required_group() -> void:
	var stage: Control = _stage(GeometryOracle.DESKTOP_16_9)
	var spec: Dictionary = {"required_groups": ["rig"]}
	var findings: Array[String] = GeometryOracle.new().audit(stage, GeometryOracle.DESKTOP_16_9, spec)
	assert_gt(findings.size(), 0, "a scene cannot opt out of its gate by forgetting add_to_group")


func test_trace_stories_rejects_an_untagged_script() -> void:
	var root: String = _temp_dir()
	_write(root.path_join("game/scripts/untagged.gd"), "extends Node\n")
	var code: int = _run_from(root, "scripts/trace-stories.sh")
	assert_ne(code, 0, "a script with no `# story:` tag must turn the gate red")


func test_trace_stories_accepts_a_tagged_script() -> void:
	var root: String = _temp_dir()
	_write(root.path_join("game/scripts/tagged.gd"), "# story: e11s01\nextends Node\n")
	var code: int = _run_from(root, "scripts/trace-stories.sh")
	assert_eq(code, 0, "a tagged script is green")


func test_the_diary_auditor_rejects_prose_and_absolute_paths() -> void:
	var dir: String = _temp_dir()
	var line: String = (
		JSON
		. stringify(
			{
				"ts": "2026-11-07T10:00:00.000Z",
				"session": "abcdef12",
				"lvl": "info",
				"ev": "save.written",
				"note": "/Users/daniel/segredo.gd",
			}
		)
	)
	_write(dir.path_join("quiqui-bad.jsonl"), line + "\n")
	var code: int = (
		OS
		. execute(
			"python3",
			[_repo_path("scripts/log_tool.py"), "--dir", dir, "audit"],
			[],
			true,
		)
	)
	assert_ne(code, 0, "an absolute path in the diary must be a red audit")


func test_gut_cannot_report_green_with_zero_tests() -> void:
	var body: String = FileAccess.get_file_as_string(_repo_path("scripts/preflight.sh"))
	assert_true(body.contains("Nothing was run"), "the zero-test guard is the only defence here")
	assert_true(body.contains("L1"), "and it lives in the test stage")


# ── fixtures ─────────────────────────────────────────────────────────────────


func _stage(background_size: Vector2) -> Control:
	var stage: Control = Control.new()
	stage.name = "Stage"
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(stage)
	var background: TextureRect = TextureRect.new()
	background.name = "Background"
	background.size = background_size
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.add_to_group("background", false)
	stage.add_child(background)
	return stage


func _temp_dir() -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEMP_ROOT))
	return ProjectSettings.globalize_path(TEMP_ROOT)


func _write(path: String, body: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(body)
	file.close()


func _repo_path(relative: String) -> String:
	## `res://` is `<repo>/game/`, the scripts and specs live one level up.
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(relative).simplify_path()


## Runs the repo script from `root` (the script resolves `game/scripts` relative to the cwd,
## so a throw-away tree is all it takes to feed it a broken one).
func _run_from(root: String, relative: String) -> int:
	var script: String = _repo_path(relative)
	var command: String = "cd '%s' && bash '%s' --strict" % [root, script]
	return OS.execute("bash", ["-c", command], [], true)


func _remove_tree(path: String) -> void:
	var absolute: String = ProjectSettings.globalize_path(path)
	var dir: DirAccess = DirAccess.open(absolute)
	if dir == null:
		return
	for name: String in dir.get_files():
		dir.remove(name)
	for name: String in dir.get_directories():
		_remove_tree(path.path_join(name))
	DirAccess.remove_absolute(absolute)
