# story: e09s03
class_name DoorBadge
extends Control
## The Vila's party door badge (e09s03, FIX-04): a lock until five pieces stand in the
## casinha, a star afterwards. It reads the same rule the party reads, so the hub and
## the party can never disagree — and it lives in a component so `vila.gd` gains no code.

@export var required_placed: int = 5
@export var locked_art: String = ""
@export var unlocked_art: String = ""

var _art: TextureRect = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art = get_node_or_null("Art") as TextureRect
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress != null and progress.has_signal("progress_changed"):
		progress.progress_changed.connect(refresh)
	refresh()


func unlocked() -> bool:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null or not progress.has_method("placed_count"):
		return false
	return int(progress.call("placed_count")) >= required_placed


func current_art_path() -> String:
	return unlocked_art if unlocked() else locked_art


## Swaps the texture only when the state actually changed: `progress_changed` fires for
## coins, outfits and every placement, and reloading art on each of those is waste.
func refresh() -> void:
	if _art == null:
		return
	var path: String = current_art_path()
	if _art.has_meta("door_badge_path") and str(_art.get_meta("door_badge_path")) == path:
		return
	_art.set_meta("door_badge_path", path)
	_art.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
