# story: e13s05
class_name OutfitCatalog
extends RefCounted
## The shipped dress-up pieces: four outfits and six accessories, all with art. The save writes only
## these ids into a slot (`ProgressManager.wear`), so a def cannot dress her in anything else.

const OUTFITS: Array[String] = ["floral_dress", "red_dress", "green_overalls", "pajamas"]
const ACCESSORIES: Array[Dictionary] = [
	{"slot": "head", "id": "flower_tiara"},
	{"slot": "head", "id": "crown"},
	{"slot": "head", "id": "yellow_hat"},
	{"slot": "neck", "id": "blue_scarf"},
	{"slot": "neck", "id": "purple_bow"},
	{"slot": "eyes", "id": "heart_glasses"},
]


static func is_wearable(slot: String, id: String) -> bool:
	if slot == SaveData.SLOT_BODY:
		return OUTFITS.has(id)
	for entry: Dictionary in ACCESSORIES:
		if str(entry["slot"]) == slot and str(entry["id"]) == id:
			return true
	return false
