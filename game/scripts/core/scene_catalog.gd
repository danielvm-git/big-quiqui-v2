# story: e11s01
# story: e12s02
# story: e14s01
# story: e14s02
# story: e14s02
class_name SceneCatalog
extends RefCounted
## Shipped legacy scenes plus data-scene ids. Tests and tables read from here.

const ALL_PATHS: Array[String] = [
	"res://scenes/titulo.tscn",
	"res://scenes/casa.tscn",
	"res://scenes/cozinha.tscn",
	"res://scenes/banheiro.tscn",
	"res://scenes/closet.tscn",
	"res://scenes/jardim.tscn",
	"res://scenes/quarto_sono.tscn",
	"res://scenes/celebracao.tscn",
	"res://scenes/vila.tscn",
	"res://scenes/roda.tscn",
	"res://scenes/mercado.tscn",
	"res://scenes/casinha.tscn",
	"res://scenes/festa.tscn",
	"res://scenes/pato_danca.tscn",
	"res://scenes/urso_puzzle.tscn",
	"res://scenes/pinguim_jogo.tscn",
	"res://scenes/album.tscn",
]

const SCENE_COUNT: int = 17

const _ID_TO_LEGACY: Dictionary = {
	"title": "res://scenes/titulo.tscn",
	"home": "res://scenes/casa.tscn",
	"kitchen": "res://scenes/cozinha.tscn",
	"bathroom": "res://scenes/banheiro.tscn",
	"closet": "res://scenes/closet.tscn",
	"playroom": "res://scenes/jardim.tscn",
	"bedroom": "res://scenes/quarto_sono.tscn",
	"celebration": "res://scenes/celebracao.tscn",
	"village": "res://scenes/vila.tscn",
	"wheel": "res://scenes/roda.tscn",
	"market": "res://scenes/mercado.tscn",
	"playhouse": "res://scenes/casinha.tscn",
	"party": "res://scenes/festa.tscn",
	"duck_dance": "res://scenes/pato_danca.tscn",
	"bear_puzzle": "res://scenes/urso_puzzle.tscn",
	"penguin_lanes": "res://scenes/pinguim_jogo.tscn",
	"album": "res://scenes/album.tscn",
}

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
}


static func count() -> int:
	return ALL_PATHS.size()


static func is_shipped(key: String) -> bool:
	if ALL_PATHS.has(key):
		return true
	return _ID_TO_LEGACY.has(key) or _ID_TO_DEF.has(key)


static func legacy_path_for_id(scene_id: String) -> String:
	return str(_ID_TO_LEGACY.get(scene_id, ""))


static func def_path_for_id(scene_id: String) -> String:
	if _ID_TO_DEF.has(scene_id):
		return str(_ID_TO_DEF[scene_id])
	var path: String = SceneDefLoader.def_tres_path(scene_id)
	if ResourceLoader.exists(path):
		return path
	return ""


static func path_for_id(scene_id: String) -> String:
	var legacy: String = legacy_path_for_id(scene_id)
	if not legacy.is_empty():
		return legacy
	return def_path_for_id(scene_id)
