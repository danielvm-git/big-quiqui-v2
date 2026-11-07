# story: e10s03
class_name CatchItem
extends TextureRect
## A falling item (ball or bubble) in the penguin catch mini-game (e10s03).
## Falls top to bottom during advance(); pops once when intercepted by Pinguim.

var kind: String = ""
var popped: bool = false


func step_down(px: float) -> void:
	position.y += px
