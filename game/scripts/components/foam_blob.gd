# story: e04s02
class_name FoamBlob
extends Control
## One soap-foam patch on QuiQui. A blob is a *region*, not a button: the sponge
## scrubs a continuous gesture and a blob is soaked when a scrub point lands inside
## it. Blobs are placed by `BathScene` from the rig's scrub hull, so containment is
## the scene's contract and this component only answers geometry questions.

signal soaked

const SOAKED_ALPHA: float = 0.0

var is_soaked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ZERO


## Global-space test, because the scrub gesture reports global points.
func contains_global_point(point: Vector2) -> bool:
	if is_soaked or not is_inside_tree():
		return false
	return get_global_rect().has_point(point)


## Idempotent: a second scrub on a soaked blob is a no-op, so the count of soaked
## blobs can never exceed the number placed.
func soak() -> bool:
	if is_soaked:
		return false
	is_soaked = true
	visible = false
	modulate.a = SOAKED_ALPHA
	soaked.emit()
	return true


## Puts a soaked blob back on the skin without recreating the node (stage restart).
func reset_blob() -> void:
	is_soaked = false
	visible = true
	modulate.a = 1.0
