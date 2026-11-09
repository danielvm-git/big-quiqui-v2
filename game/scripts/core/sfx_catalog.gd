# story: e12s04
# story: e13s01
class_name SfxCatalog
extends RefCounted
## Map sfx ids from step data to shipped streams.

const PATH_FOR_ID: Dictionary = {
	"sfx_chomp": "res://assets/audio/sfx/chomp.ogg",
	"sfx_soft_error": "res://assets/audio/sfx/soft_error.ogg",
	"sfx_heart": "res://assets/audio/sfx/heart.ogg",
	"sfx_rinse": "res://assets/audio/sfx/rinse.ogg",
	"sfx_success": "res://assets/audio/sfx/success.ogg",
}


static func path(sfx_id: String) -> String:
	if not Ids.is_valid(sfx_id):
		return ""
	var found: Variant = PATH_FOR_ID.get(sfx_id, "")
	return str(found)
