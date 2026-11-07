# story: e09s02
class_name FurnitureProp
extends TouchDraggable
## One piece of furniture she owns, draggable into the room (e09s02). Everything about
## the gesture lives in `TouchDraggable`; this only carries the id, the art and the
## normalized bookkeeping.

const PROP_SIZE: float = 148.0

var item_id: String = ""

var data: FurnitureData = null


func setup(item: FurnitureData) -> void:
	data = item
	item_id = "" if item == null else item.id
	name = "Prop_" + (item_id if not item_id.is_empty() else "unknown")
	size = Vector2(PROP_SIZE, PROP_SIZE)
	mode = Mode.FREE_PLACEMENT
	add_to_group("hit_target", true)
	add_child(_art(item))


## The centre of the piece, which is what a normalized coordinate describes.
func center() -> Vector2:
	return get_global_rect().get_center()


func _art(item: FurnitureData) -> TextureRect:
	var art: TextureRect = TextureRect.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if item != null:
		art.texture = item.texture()
	return art
