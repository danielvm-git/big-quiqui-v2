# story: e12s02
class_name SceneMedia
extends RefCounted
## Resolve background and music ids from scene data to shipped asset paths.


static func background_path(background_id: String) -> String:
	if not Ids.is_valid(background_id) or not background_id.begins_with("bg_"):
		return ""
	var file: String = "%s.jpg" % background_id
	return "res://assets/art/backgrounds/%s" % file


static func music_path(music_id: String) -> String:
	if not Ids.is_valid(music_id) or not music_id.begins_with("music_"):
		return ""
	var stem: String = music_id.substr("music_".length())
	return "res://assets/audio/music/%s.ogg" % stem


static func background_exists(background_id: String) -> bool:
	var path: String = background_path(background_id)
	return not path.is_empty() and ResourceLoader.exists(path)


static func music_exists(music_id: String) -> bool:
	if music_id.is_empty():
		return true
	var path: String = music_path(music_id)
	return not path.is_empty() and ResourceLoader.exists(path)
