# story: e12s02
class_name SceneDefLoader
extends RefCounted
## Load and validate `SceneDef` resources; reject bad data before the player sees it.

const REJECT_EV: String = "scene.def_rejected"
const DATA_DIR: String = "res://data/scenes/"


static func def_tres_path(scene_id: String) -> String:
	if not Ids.is_valid(scene_id):
		return ""
	return "%s%s.tres" % [DATA_DIR, scene_id]


static func load_by_id(scene_id: String) -> SceneDef:
	if not Ids.is_valid(scene_id):
		_reject(scene_id, "invalid_id")
		return null
	var path: String = def_tres_path(scene_id)
	if not ResourceLoader.exists(path):
		_reject(scene_id, "missing_def")
		return null
	var loaded: Resource = load(path)
	if not loaded is SceneDef:
		_reject(scene_id, "wrong_type")
		return null
	return validate(loaded as SceneDef)


static func validate(def: SceneDef) -> SceneDef:
	if def == null:
		_reject("", "null_def")
		return null
	var reason: String = _def_problem(def)
	if not reason.is_empty():
		_reject(def.id, reason)
		return null
	return def


static func _def_problem(def: SceneDef) -> String:
	if not Ids.is_valid(def.id):
		return "invalid_id"
	if def.background_id.is_empty() or not SceneMedia.background_exists(def.background_id):
		return "missing_background"
	if not def.music_id.is_empty() and not SceneMedia.music_exists(def.music_id):
		return "missing_music"
	if def.steps.is_empty():
		return "empty_steps"
	for step_res: Resource in def.steps:
		var reason: String = _step_problem(step_res)
		if not reason.is_empty():
			return reason
	return ""


static func _step_problem(step_res: Resource) -> String:
	if step_res == null or not step_res is StepDef:
		return "unknown_template"
	var step: StepDef = step_res as StepDef
	if not TemplateCatalog.is_known(step.template_id):
		return "unknown_template"
	return StepParams.problem(step)


static func _reject(scene_id: String, reason: String) -> void:
	var data: Dictionary = {"reason": reason}
	if Ids.is_valid(scene_id):
		data["scene"] = "scene.%s" % scene_id
	LogSink.emit_to_diary(REJECT_EV, data)
