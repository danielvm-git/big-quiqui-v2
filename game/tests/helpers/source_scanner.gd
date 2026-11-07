# story: e11s01
class_name SourceScanner
extends RefCounted
## INV-05/INV-06/INV-07 — static readers for the shipped source.
##
## The game is the artifact under test here, not a scenario: these helpers read
## `game/scripts/**` and `game/scenes/*.tscn` as text and as script constants, so a
## gate can state a rule about *all* of it (every emitted event id, every FSM table,
## every scene root) instead of about the one scene a story happened to touch.

const SCRIPT_ROOTS: Array[String] = ["res://scripts"]
const SCENE_ROOT: String = "res://scenes"


static func scripts() -> Array[String]:
	var found: Array[String] = []
	for root: String in SCRIPT_ROOTS:
		found.append_array(_walk(root, ".gd"))
	found.sort()
	return found


static func scenes() -> Array[String]:
	return _walk(SCENE_ROOT, ".tscn")


## The scene builders and dev tools. They are shipped source too: a builder that names a
## missing texture produces a scene that boots with a hole in it.
static func tool_scripts() -> Array[String]:
	return _walk("res://tools", ".gd")


static func _walk(path: String, suffix: String) -> Array[String]:
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
				found.append_array(_walk(child, suffix))
		elif name.ends_with(suffix):
			found.append(child)
		name = dir.get_next()
	dir.list_dir_end()
	return found


static func text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


## Every event id the shipped scripts pass to the diary, in source order.
## `_log("x", …)`, `_emit("x", …)`, `Log.event("x", …)`, `emit_to_diary("x", …)`. The call
## is often wrapped over several lines, so the gap after the paren allows whitespace.
static func event_ids() -> Array[String]:
	var pattern: RegEx = _regex('(?:Log\\.event\\(|emit_to_diary\\(|_log\\(|_emit\\()[\\s]*"([a-z0-9_.:]*)')
	var from_arg: RegEx = _regex('emit_from\\([^,]+,[\\s]*"([a-z0-9_.:]*)"')
	var ids: Array[String] = []
	for path: String in scripts():
		var body: String = text(path)
		for regex: RegEx in [pattern, from_arg]:
			for found: RegExMatch in regex.search_all(body):
				var id: String = found.get_string(1)
				if not ids.has(id):
					ids.append(id)
	return ids


## Every `res://` literal in the scripts and scenes, deduplicated and sorted.
## Comment lines are dropped first: a path quoted inside a doc comment (the BUG-013 note in
## `wish_bubble.gd` names `res://assets/art/../../x.png` as the string it once accepted) is
## prose about a path, not a reference to one.
static func res_paths() -> Array[String]:
	var pattern: RegEx = _regex("res://[A-Za-z0-9_./-]+")
	var found: Array[String] = []
	for path: String in scripts() + tool_scripts() + scenes():
		for hit: RegExMatch in pattern.search_all(_without_comments(text(path))):
			var value: String = hit.get_string(0)
			if not found.has(value):
				found.append(value)
	found.sort()
	return found


static func _without_comments(body: String) -> String:
	var kept: Array[String] = []
	for line: String in body.split("\n"):
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with("#") or trimmed.begins_with(";"):
			continue
		kept.append(line)
	return "\n".join(kept)


## The constants a script declares (STATE_*, LEGAL_EDGES, …), or an empty map.
static func constants_of(path: String) -> Dictionary:
	var script: Script = load(path) as Script
	if script == null:
		return {}
	return script.get_script_constant_map()


static func _regex(pattern: String) -> RegEx:
	var regex: RegEx = RegEx.new()
	regex.compile(pattern)
	return regex
