# story: e15s01
class_name PaintCatalog
extends RefCounted
## Palette color ids for paint and fill steps — no paths, only ids.

const COLORS: Dictionary = {
	"paint_red": Color(0.92, 0.22, 0.18, 1.0),
	"paint_blue": Color(0.2, 0.45, 0.92, 1.0),
	"paint_yellow": Color(0.96, 0.82, 0.18, 1.0),
	"paint_green": Color(0.22, 0.72, 0.35, 1.0),
}


static func is_paint(paint_id: String) -> bool:
	return COLORS.has(paint_id)


static func color_of(paint_id: String) -> Color:
	var found: Variant = COLORS.get(paint_id, Color.WHITE)
	return found as Color
