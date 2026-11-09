# story: e01s02
# story: e12s02
class_name SceneDiarySlug
extends RefCounted
## Diary-shaped scene ids from legacy paths or player def ids.


static func from_path(path: String) -> String:
	var base: String = path.get_file().get_basename().to_lower()
	var out: String = ""
	for character: String in base:
		out += character if character.is_valid_identifier() or character.is_valid_int() else "_"
	return "scene." + (out if not out.is_empty() else "unknown")


static func for_player_def(player_path: String, path: String, def_id: String) -> String:
	if path == player_path and not def_id.is_empty():
		return SceneManagerDefNav.scene_slug_for_id(def_id)
	return from_path(path)
