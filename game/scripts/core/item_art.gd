# story: e13s02
# story: e13s05
class_name ItemArt
extends RefCounted
## Picture for a def id. The id passes the `Ids` grammar and the directory is a const, so no
## outside text builds a path. A missing picture is a star and a diary line, never a blank target.

const DIRS: Array[String] = [
	"res://assets/art/items/",
	"res://assets/art/furniture/",
	"res://assets/art/friends/",
	"res://assets/art/effects/",
	"res://assets/art/ui/",
]
const FALLBACK: String = "res://assets/art/ui/star.png"


static func texture(art_id: String) -> Texture2D:
	var path: String = path_for(art_id)
	if path.is_empty():
		LogSink.emit_to_diary("item.missing_art", {"item": "unknown"})
		return load(FALLBACK) as Texture2D
	return load(path) as Texture2D


static func path_for(art_id: String) -> String:
	if not Ids.is_valid(art_id):
		return ""
	for dir: String in DIRS:
		var path: String = "%s%s.png" % [dir, art_id]
		if ResourceLoader.exists(path):
			return path
	return ""


static func has_art(art_id: String) -> bool:
	return not path_for(art_id).is_empty()


static func icon(art_id: String, edge: float) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.name = "Art"
	rect.texture = texture(art_id)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(edge, edge)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect
