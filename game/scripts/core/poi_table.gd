# story: e10s04
# story: e14s05
class_name PoiTable
extends RefCounted
## POI names map to catalogue scene ids, never to legacy `.tscn` paths.

const _POI_SCENE_IDS: Dictionary = {
	POI_CASA: "home",
	POI_RODA: "wheel",
	POI_MERCADO: "market",
	POI_CASINHA: "playhouse",
	POI_FESTA: "party",
	POI_ALBUM: "album",
}

const POI_CASA: String = "CASA"
const POI_RODA: String = "RODA"
const POI_RECYCLING: String = "RECYCLING"
const POI_MERCADO: String = "MERCADO"
const POI_CASINHA: String = "CASINHA"
const POI_FESTA: String = "FESTA"
const POI_ALBUM: String = "ALBUM"


static func scene_id_for_poi(poi: String) -> String:
	return str(_POI_SCENE_IDS.get(poi, ""))


static func path_for_poi(poi: String) -> String:
	return scene_id_for_poi(poi)
