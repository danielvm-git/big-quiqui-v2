# story: e13s03
class_name SceneNav
extends RefCounted
## One way to open a room by catalogue id: a data scene when one exists, otherwise the shipped
## legacy scene. The id passes `Ids` and the paths come from `SceneCatalog`, never from the caller.


static func open(manager: Node, scene_id: String) -> bool:
	if manager == null or not Ids.is_valid(scene_id) or not SceneCatalog.is_shipped(scene_id):
		return false
	if not SceneCatalog.def_path_for_id(scene_id).is_empty() and manager.has_method("request_def"):
		return bool(manager.call("request_def", scene_id))
	var legacy: String = SceneCatalog.legacy_path_for_id(scene_id)
	if legacy.is_empty() or not manager.has_method("request_scene"):
		return false
	return bool(manager.call("request_scene", legacy))
