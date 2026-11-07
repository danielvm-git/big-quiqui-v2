# story: e11s01
class_name SceneCatalog
extends RefCounted
## The 17 shipped playable scenes (DESIGN_PLAN_LATEST § inventory). MBT and the gallery
## read this list — never a hand-maintained duplicate in a test file.

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


static func count() -> int:
	return ALL_PATHS.size()


static func is_shipped(path: String) -> bool:
	return ALL_PATHS.has(path)
