# story: e01s01
extends SceneTree
## Type gate — compiles every GDScript under res://scripts, res://components,
## res://scenes and res://tests so Godot's strict-typing warnings
## (debug/gdscript/warnings/untyped_declaration=2) fail the build.
##
## Uses GDScript.reload() instead of ResourceLoader.load(): a parse error inside
## load() aborts the calling frame, so a loader-based gate reports 0 failures.
##
## Usage: godot --headless --path game -s res://tools/type_gate.gd
## Exit:  0 = every script compiles under strict typing, 1 = at least one failed.

const ROOTS: Array[String] = [
	"res://scripts",
	"res://components",
	"res://scenes",
	"res://tests",
]

var _checked: int = 0
var _failed: int = 0


func _init() -> void:
	for root: String in ROOTS:
		_walk(root)
	print("type_gate: %d scripts checked, %d failed" % [_checked, _failed])
	quit(1 if _failed > 0 else 0)


func _walk(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var full: String = path.path_join(entry)
			if dir.current_is_dir():
				_walk(full)
			elif entry.ends_with(".gd"):
				_check(full)
		entry = dir.get_next()
	dir.list_dir_end()


func _check(path: String) -> void:
	_checked += 1
	# Load the REAL script and re-parse it. A compiled copy cannot work: keeping the
	# declaration collides with the registered global class, and rewriting it breaks
	# the file's own `-> SelfName` return types. `load()` also survives a parse error
	# here (it returns the broken script, `reload()` reports 43), so the loop keeps
	# counting instead of aborting on the first bad file.
	var loaded: Variant = load(path)
	if loaded == null:
		_failed += 1
		printerr("type_gate: FAILED %s (not loadable)" % path)
		return
	var script: GDScript = loaded as GDScript
	if script == null:
		_failed += 1
		printerr("type_gate: FAILED %s (not a GDScript)" % path)
		return
	var err: int = script.reload()
	if err != OK:
		_failed += 1
		printerr("type_gate: FAILED %s (%s)" % [path, error_string(err)])
