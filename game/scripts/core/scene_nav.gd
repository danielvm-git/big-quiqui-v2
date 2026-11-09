# story: e13s03
# story: e14s05
class_name SceneNav
extends RefCounted
## One way to open a room by catalogue id through the player and a def.


static func open(manager: Node, scene_id: String) -> bool:
	if manager == null or not Ids.is_valid(scene_id) or not SceneCatalog.is_shipped(scene_id):
		return false
	if SceneCatalog.def_path_for_id(scene_id).is_empty() or not manager.has_method("request_def"):
		return false
	return bool(manager.call("request_def", scene_id))
