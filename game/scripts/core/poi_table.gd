# story: e10s04
class_name PoiTable
extends RefCounted
## Central registry of Vila Points of Interest (POIs) and their scene targets (e10s04).
## Extracted from VilaScene to enforce the 300-line bar and allow clean external queries.

const CASA_PATH: String = "res://scenes/casa.tscn"
const RODA_PATH: String = "res://scenes/roda.tscn"
const MERCADO_PATH: String = "res://scenes/mercado.tscn"
const CASINHA_PATH: String = "res://scenes/casinha.tscn"
const FESTA_PATH: String = "res://scenes/festa.tscn"
const ALBUM_PATH: String = "res://scenes/album.tscn"

const POI_CASA: String = "CASA"
const POI_RODA: String = "RODA"
const POI_RECYCLING: String = "RECYCLING"
const POI_MERCADO: String = "MERCADO"
const POI_CASINHA: String = "CASINHA"
const POI_FESTA: String = "FESTA"
const POI_ALBUM: String = "ALBUM"

const SCENES: Dictionary = {
	POI_CASA: CASA_PATH,
	POI_RODA: RODA_PATH,
	POI_RECYCLING: "",
	POI_MERCADO: MERCADO_PATH,
	POI_CASINHA: CASINHA_PATH,
	POI_FESTA: FESTA_PATH,
	POI_ALBUM: ALBUM_PATH,
}
