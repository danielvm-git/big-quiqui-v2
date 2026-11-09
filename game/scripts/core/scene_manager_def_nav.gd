# story: e12s02
class_name SceneManagerDefNav
extends RefCounted
## Def payload channel for SceneManager — keeps the autoload under the 300-line bar.

var pending_def_id: String = ""
var current_def_id: String = ""
var _staged_def: SceneDef = null
var _pending_def_stash: SceneDef = null


func reset() -> void:
	pending_def_id = ""
	current_def_id = ""
	_staged_def = null
	_pending_def_stash = null


func consume_def() -> SceneDef:
	var out: SceneDef = _staged_def
	_staged_def = null
	return out


func stage(scene_id: String, def: SceneDef) -> void:
	current_def_id = scene_id
	_staged_def = def


func clear_current_def() -> void:
	current_def_id = ""


func apply_pending() -> void:
	if pending_def_id.is_empty():
		return
	current_def_id = pending_def_id
	_staged_def = _pending_def_stash
	pending_def_id = ""
	_pending_def_stash = null


func clear_pending_def() -> void:
	pending_def_id = ""
	_pending_def_stash = null


func park_def(scene_id: String, def: SceneDef, is_idle: bool, player_path: String) -> String:
	if scene_id == pending_def_id:
		return player_path
	if not is_idle:
		pending_def_id = scene_id
		_pending_def_stash = def
		return player_path
	return ""


static func scene_slug_for_id(scene_id: String) -> String:
	return "scene.%s" % scene_id if Ids.is_valid(scene_id) else "scene.unknown"


static func load_def(scene_id: String) -> SceneDef:
	return SceneDefLoader.load_by_id(scene_id)


static func celebrate_may_continue(scene_id: String, home_id: String, celebration_id: String) -> bool:
	return scene_id == home_id or scene_id == celebration_id
