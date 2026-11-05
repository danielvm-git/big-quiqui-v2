# story: e01s04
class_name QuiQuiRig
extends Control
## Layered character rig (ADR-003): `Control` layout box + foot-pivoted `Node2D`
## art stack (Body 0 → Outfit 10 → Expression 20 → Headwear 30 → Neck 40 → Glasses 50).

const ART_ROOT: String = "res://assets/art/quiqui/"
const NEUTRAL_EXPRESSION: String = "base"
const BLINK_EXPRESSION: String = "pisca"
const BREATH_PERIOD_SEC: float = 2.2
const BREATH_X: float = 0.018
const BREATH_Y: float = 0.022
const BLINK_MIN_SEC: float = 2.8
const BLINK_MAX_SEC: float = 5.2
const BLINK_HOLD_SEC: float = 0.130
const Z_BODY: int = 0
const Z_OUTFIT: int = 10
const Z_EXPRESSION: int = 20
const Z_HEADWEAR: int = 30
const Z_NECK: int = 40
const Z_GLASSES: int = 50
const DEFAULT_ART_ASPECT: float = 1.0
const BOX_FIT_EPSILON: float = 0.5

signal expression_changed(expression_id: String)
signal outfit_changed(outfit_id: String)
signal tapped

var pivot: Node2D = null
var body: Sprite2D = null
var outfit: Sprite2D = null
var expression: Sprite2D = null
var headwear: Sprite2D = null
var neck: Sprite2D = null
var glasses: Sprite2D = null
var mouth_zone: Control = null
var expression_id: String = ""
var outfit_id: String = ""
var manual_step: bool = false
var seed_value: int = 20261104
var taps: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spring: SquashSpring = SquashSpring.new()
var _time: float = 0.0
var _next_blink_at: float = 0.0
var _blink_until: float = -1.0
var _opaque: Dictionary = {}


func _ready() -> void:
	_rng.seed = seed_value
	_next_blink_at = _rng.randf_range(BLINK_MIN_SEC, BLINK_MAX_SEC)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_rig()
	set_expression(NEUTRAL_EXPRESSION)
	_refit()


func _refit() -> void:
	if pivot == null:
		return
	if is_equal_approx(anchor_left, anchor_right) and is_equal_approx(anchor_left, 0.5):
		var seen: Rect2 = opaque_rect(expression.texture) if expression != null else Rect2()
		var aspect: float = seen.size.x / seen.size.y if seen.has_area() else DEFAULT_ART_ASPECT
		var wanted: float = size.y * aspect
		if wanted > 1.0 and absf(size.x - wanted) >= BOX_FIT_EPSILON:
			offset_left = -wanted * 0.5
			offset_right = wanted * 0.5
	pivot.position = Vector2(size.x * 0.5, size.y)
	_update_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refit()


func _process(delta: float) -> void:
	if not manual_step:
		advance(delta)


func _gui_input(event: InputEvent) -> void:
	if event.device == -1:
		return
	var pressed_tap: bool = (
		(event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	)
	if pressed_tap and _hits_character(event.get("position") as Vector2):
		taps += 1
		play_squash()
		tapped.emit()
		LogSink.emit_from(self, "rig.tap", {"expression": expression_id})


func _hits_character(point: Vector2) -> bool:
	var painted: Rect2 = get_visual_global_rect()
	return not painted.has_area() or painted.has_point(point) or painted.has_point(global_position + point)


func advance(delta: float) -> void:
	var step: float = maxf(delta, 0.0)
	_time += step
	if pivot != null and not _spring.is_running():
		var wave: float = sin(_time * BREATH_PERIOD_SEC)
		pivot.scale = Vector2(1.0 - BREATH_X * wave, 1.0 + BREATH_Y * wave)
	_advance_blink()
	if _spring.is_running():
		_spring.advance(step)
		if pivot != null:
			pivot.scale = _spring.scale


func _advance_blink() -> void:
	if _blink_until >= 0.0:
		if _time >= _blink_until:
			_blink_until = -1.0
			if expression_id == BLINK_EXPRESSION:
				_apply_expression(NEUTRAL_EXPRESSION)
		return
	if _time < _next_blink_at:
		return
	if expression_id == NEUTRAL_EXPRESSION:
		_apply_expression(BLINK_EXPRESSION)
		_blink_until = _time + BLINK_HOLD_SEC
	_next_blink_at = _time + _rng.randf_range(BLINK_MIN_SEC, BLINK_MAX_SEC)


func play_squash() -> void:
	_spring.start()
	if pivot != null:
		pivot.scale = _spring.scale


func is_squashing() -> bool:
	return _spring.is_running()


func is_blinking() -> bool:
	return _blink_until >= 0.0


func set_expression(id: String) -> bool:
	if not Ids.is_valid(id):
		LogSink.emit_from(self, "rig.invalid_expression", {"expression": "invalid"})
		return false
	if id == expression_id and expression != null:
		return true
	if _load_art(id) == null:
		LogSink.emit_from(self, "rig.missing_art", {"expression": id})
		return false
	_apply_expression(id)
	return true


func set_outfit(id: String) -> bool:
	if id.is_empty():
		if outfit != null:
			outfit.visible = false
			outfit.texture = null
		outfit_id = ""
		outfit_changed.emit("")
		return true
	if not Ids.is_valid(id):
		LogSink.emit_from(self, "rig.invalid_outfit", {"outfit": "invalid"})
		return false
	var texture: Texture2D = _load_art(id)
	if texture == null:
		LogSink.emit_from(self, "rig.missing_art", {"outfit": id})
		return false
	outfit.texture = texture
	outfit.visible = true
	outfit_id = id
	outfit_changed.emit(id)
	return true


## Union of every visible sprite's opaque pixels in global coordinates.
func get_visual_global_rect() -> Rect2:
	var rect: Rect2 = Rect2()
	var started: bool = false
	for sprite: Sprite2D in [body, outfit, expression, headwear, neck, glasses]:
		if sprite == null or not sprite.visible or sprite.texture == null:
			continue
		var used: Rect2 = opaque_rect(sprite.texture)
		if not used.has_area():
			continue
		var top_left: Vector2 = sprite.global_position - sprite.texture.get_size() * 0.5 * sprite.global_scale
		var sprite_rect: Rect2 = Rect2(top_left + used.position * sprite.global_scale, used.size * sprite.global_scale)
		rect = sprite_rect if not started else rect.merge(sprite_rect)
		started = true
	return rect


## Opaque box in frame pixels, cached by `get_instance_id()` (logs once per unreadable texture).
func opaque_rect(texture: Texture2D) -> Rect2:
	if texture == null:
		return Rect2()
	var key: int = texture.get_instance_id()
	if _opaque.has(key):
		return _opaque[key] as Rect2
	var used: Rect2 = Rect2()
	var image: Image = texture.get_image()
	if image != null and not image.is_empty():
		var opaque: Rect2i = image.get_used_rect()
		if opaque.size.x > 0 and opaque.size.y > 0:
			used = Rect2(Vector2(opaque.position), Vector2(opaque.size))
	if not used.has_area():
		LogSink.emit_from(self, "rig.opaque_unreadable", {"art": texture.resource_path.get_file()})
	_opaque[key] = used
	return used


func reset() -> void:
	taps = 0
	_time = 0.0
	_blink_until = -1.0
	_spring.stop()
	_rng.seed = seed_value
	_next_blink_at = _rng.randf_range(BLINK_MIN_SEC, BLINK_MAX_SEC)
	set_outfit("")
	if pivot != null:
		pivot.scale = Vector2.ONE
	set_expression(NEUTRAL_EXPRESSION)


func _build_rig() -> void:
	pivot = Node2D.new()
	pivot.name = "Pivot"
	pivot.position = Vector2(size.x * 0.5, size.y)
	add_child(pivot)
	body = _make_sprite("Body", Z_BODY)
	outfit = _make_sprite("Outfit", Z_OUTFIT)
	expression = _make_sprite("Expression", Z_EXPRESSION)
	headwear = _make_sprite("Headwear", Z_HEADWEAR)
	neck = _make_sprite("Neck", Z_NECK)
	glasses = _make_sprite("Glasses", Z_GLASSES)
	for layer: Sprite2D in [outfit, headwear, neck, glasses]:
		layer.visible = false
	mouth_zone = Control.new()
	mouth_zone.name = "MouthZone"
	mouth_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mouth_zone)


func _make_sprite(sprite_name: String, layer: int) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = sprite_name
	sprite.z_index = layer
	sprite.centered = true
	pivot.add_child(sprite)
	return sprite


func _apply_expression(id: String) -> void:
	var texture: Texture2D = _load_art(id)
	if texture == null or expression == null:
		return
	expression.texture = texture
	expression.visible = true
	expression_id = id
	_refit()
	expression_changed.emit(id)


func _update_layout() -> void:
	if expression == null or expression.texture == null:
		return
	var art: Vector2 = expression.texture.get_size()
	var used: Rect2 = opaque_rect(expression.texture)
	var seen: Vector2 = used.size if used.has_area() else art
	var box: Vector2 = size if size.y > 1.0 else seen
	var factor: float = box.y / seen.y if seen.y > 0.0 else 1.0
	var shift: Vector2 = Vector2(
		art.x * factor * 0.5 - (used.position.x + used.size.x * 0.5) * factor,
		art.y * factor - (used.position.y + used.size.y) * factor,
	)
	for sprite: Sprite2D in [body, outfit, expression, headwear, neck, glasses]:
		if sprite != null:
			sprite.scale = Vector2.ONE * factor
			sprite.position = Vector2(0.0, -art.y * factor * 0.5) + shift
	if mouth_zone != null:
		mouth_zone.size = seen * factor * 0.18
		mouth_zone.position = Vector2(size.x * 0.5 - mouth_zone.size.x * 0.5, size.y - seen.y * factor * 0.62)


func _load_art(id: String) -> Texture2D:
	var path: String = "%squiqui_%s.png" % [ART_ROOT, id]
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
