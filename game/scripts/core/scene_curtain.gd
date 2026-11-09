# story: e01s02
class_name SceneCurtain
extends RefCounted
## Fade curtain layer owned by SceneManager — kept out of the autoload for the line bar.

const LAYER: int = 128

var layer: CanvasLayer = null
var rect: ColorRect = null


func build(host: Node) -> void:
	layer = CanvasLayer.new()
	layer.name = "SceneCurtainLayer"
	layer.layer = LAYER
	host.add_child(layer)
	rect = ColorRect.new()
	rect.name = "SceneCurtain"
	rect.color = Color(0.0, 0.0, 0.0, 0.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)


func set_alpha(alpha: float) -> void:
	if rect == null:
		return
	var colour: Color = rect.color
	colour.a = clampf(alpha, 0.0, 1.0)
	rect.color = colour


func alpha() -> float:
	return rect.color.a if rect != null else 0.0
