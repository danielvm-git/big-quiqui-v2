# story: e03s02
class_name ItemData
extends Resource
## One shipped item as typed data. Bad data degrades to a null texture and a
## diary line, so a scene stays playable (CONVENTIONS §4).

@export var id: String = ""
@export var art_path: String = ""


func texture() -> Texture2D:
	if not Ids.is_valid(id):
		LogSink.emit_to_diary("item.invalid_id", {"item": "invalid"})
		return null
	var art: Texture2D = null
	if ResourceLoader.exists(art_path):
		art = load(art_path) as Texture2D
	if art == null:
		LogSink.emit_to_diary("item.missing_art", {"item": id})
	return art
