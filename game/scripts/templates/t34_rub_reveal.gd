# story: e13s01
extends RefCounted
## Reveal layers in def order. The template knows no room.

var _surface: RubSurface = RubSurface.new()
var _ctx: TemplateContext = null
var _gone: Array[bool] = []


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_surface.bind(ctx, _on_scrubbed, "reveal")
	for _layer: Control in _surface.layers:
		_gone.append(false)


func teardown() -> void:
	_surface.teardown()
	_gone.clear()


func advance(_delta: float) -> void:
	_surface.fit_layers()
	_reveal_due()


func progress() -> float:
	return _surface.rub.progress()


func begin_gesture() -> void:
	_surface.begin_gesture()


func end_gesture() -> void:
	_surface.end_gesture()


func note_rub(point: Vector2) -> bool:
	var counted: bool = _surface.note_rub(point)
	if counted:
		_reveal_due()
	return counted


func layer_alpha(index: int) -> float:
	return _surface.alpha(index)


func tool() -> TouchDraggable:
	return _surface.tool


func _on_scrubbed(point: Vector2) -> void:
	note_rub(point)


func _reveal_due() -> void:
	var count: int = _surface.layers.size()
	var ratio: float = _surface.rub.progress()
	for index: int in range(count):
		if _gone[index] or ratio + 0.0001 < float(index + 1) / float(count):
			continue
		_gone[index] = true
		_surface.fade_out(index)
		TemplateKit.play_hit(_ctx, "template.reveal", {"layer": index}, index)
