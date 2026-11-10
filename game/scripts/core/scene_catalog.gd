# story: e11s01
# story: e12s02
# story: e14s01
# story: e14s02
# story: e14s04
# story: e14s05
# story: e15s01
# story: e16s01
class_name SceneCatalog
extends RefCounted
## The seventeen playable room ids. Navigation always loads `scene_player.tscn` with a def.

const SCENE_COUNT: int = 17

const SHIPPED_IDS: Array[String] = [
	"title",
	"home",
	"kitchen",
	"bathroom",
	"closet",
	"playroom",
	"bedroom",
	"celebration",
	"village",
	"wheel",
	"market",
	"playhouse",
	"party",
	"duck_dance",
	"bear_puzzle",
	"penguin_lanes",
	"album",
]

const PLAYER_SCENE: String = "res://scenes/scene_player.tscn"

const _ID_TO_DEF: Dictionary = {
	"dev_smoke": "res://data/scenes/dev_smoke.tres",
	"kitchen": "res://data/scenes/kitchen.tres",
	"bathroom": "res://data/scenes/bathroom.tres",
	"closet": "res://data/scenes/closet.tres",
	"playroom": "res://data/scenes/playroom.tres",
	"bedroom": "res://data/scenes/bedroom.tres",
	"title": "res://data/scenes/title.tres",
	"home": "res://data/scenes/home.tres",
	"village": "res://data/scenes/village.tres",
	"celebration": "res://data/scenes/celebration.tres",
	"market": "res://data/scenes/market.tres",
	"duck_dance": "res://data/scenes/duck_dance.tres",
	"album": "res://data/scenes/album.tres",
	"playhouse": "res://data/scenes/playhouse.tres",
	"bear_puzzle": "res://data/scenes/bear_puzzle.tres",
	"party": "res://data/scenes/party.tres",
	"wheel": "res://data/scenes/wheel.tres",
	"penguin_lanes": "res://data/scenes/penguin_lanes.tres",
	"coloring": "res://data/scenes/coloring.tres",
	"find_toy": "res://data/scenes/find_toy.tres",
	"memory_match": "res://data/scenes/memory_match.tres",
	"peekaboo": "res://data/scenes/peekaboo.tres",
	"tap_moving_probe": "res://data/scenes/tap_moving_probe.tres",
	"ride_probe": "res://data/scenes/ride_probe.tres",
	"float_pop_probe": "res://data/scenes/float_pop_probe.tres",
	"slice_probe": "res://data/scenes/slice_probe.tres",
	"cups_probe": "res://data/scenes/cups_probe.tres",
	"serve_probe": "res://data/scenes/serve_probe.tres",
	"groom_probe": "res://data/scenes/groom_probe.tres",
	"outro_probe": "res://data/scenes/outro_probe.tres",
	"progress_probe": "res://data/scenes/progress_probe.tres",
}


static func count() -> int:
	return SCENE_COUNT


static func is_shipped(key: String) -> bool:
	return SHIPPED_IDS.has(key) or _ID_TO_DEF.has(key)


static func legacy_path_for_id(_scene_id: String) -> String:
	return ""


static func def_path_for_id(scene_id: String) -> String:
	if _ID_TO_DEF.has(scene_id):
		return str(_ID_TO_DEF[scene_id])
	var path: String = SceneDefLoader.def_tres_path(scene_id)
	if ResourceLoader.exists(path):
		return path
	return ""


static func path_for_id(scene_id: String) -> String:
	return def_path_for_id(scene_id)


static func all_shipped_ids() -> Array[String]:
	var ids: Array[String] = []
	for scene_id: String in SHIPPED_IDS:
		ids.append(scene_id)
	return ids
