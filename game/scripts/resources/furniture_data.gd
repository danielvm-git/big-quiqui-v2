# story: e09s01
class_name FurnitureData
extends Resource
## One shipped Lote-6 furniture piece as typed data (e09s01). Bad data degrades to a
## null texture and a diary line, so a room stays playable (CONVENTIONS §4).

@export var id: String = ""
@export var art_path: String = ""
@export var price_coins: int = 0


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
