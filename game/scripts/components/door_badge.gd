# story: e09s03
# story: e10s04
class_name DoorBadge
extends Control
## The Vila's party and album door badge (e09s03, e10s04, FIX-04): a lock until
## required progress is met, a star afterwards. Dispatches on rule ("placed" | "stars").

@export var rule: String = "placed"
@export var required_placed: int = 5
@export var required_stars: int = 1
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
	if progress == null:
		return false
	if rule == "stars":
		return _total_stars(progress) >= required_stars
	if not progress.has_method("placed_count"):
		return false
	return int(progress.call("placed_count")) >= required_placed


func _total_stars(progress: Node) -> int:
	var total: int = 0
	for id: String in FriendCatalog.FRIEND_IDS:
		total += int(progress.call("stars_of", id))
	return total


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
