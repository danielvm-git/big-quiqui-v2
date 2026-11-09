# story: e10s03
class_name CatchItem
extends TextureRect
## A falling item (ball or bubble) in the penguin catch mini-game (e10s03).
## Falls top to bottom during advance(); pops once when intercepted by Pinguim.

const BOLA_ART: String = "res://assets/art/items/ball.png"
const BOLHA_ART: String = "res://assets/art/effects/bubble.png"
const ITEM_SIZE: Vector2 = Vector2(80.0, 80.0)

var kind: String = ""
var popped: bool = false


static func create(item_kind: String, spawn_pos: Vector2) -> CatchItem:
	var art_path: String = BOLA_ART if item_kind == "ball" else BOLHA_ART
	var tex: Texture2D = load(art_path) as Texture2D if ResourceLoader.exists(art_path) else null
	var item: CatchItem = CatchItem.new()
	item.kind = item_kind
	item.texture = tex
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.size = ITEM_SIZE
	item.position = spawn_pos
	return item


func step_down(px: float) -> void:
	position.y += px
