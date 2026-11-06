# story: e01s04
class_name QuiQuiRig
extends Control
## Layered character rig (ADR-003): `Control` layout box + foot-pivoted `Node2D` art stack.

const ART_ROOT: String = "res://assets/art/quiqui/"
const NEUTRAL_EXPRESSION: String = "base"
const BLINK_EXPRESSION: String = "pisca"
const MOUTH_ANTICIPATION_PX: float = 220.0
const ANTICIPATION_EXPRESSION: String = "boca_aberta"
const BREATH_PERIOD_SEC: float = 2.2
const BREATH_X: float = 0.018
const BREATH_Y: float = 0.022
const BLINK_MIN_SEC: float = 2.8
const BLINK_MAX_SEC: float = 5.2
const BLINK_HOLD_SEC: float = 0.130
## Accessory slots (ADR-003). One item per slot: a second hat replaces the first
## instead of stacking, which is what keeps the character readable.
const SLOT_BODY: String = "body"
const SLOT_HEAD: String = "head"
const SLOT_NECK: String = "neck"
const SLOT_EYES: String = "eyes"
## Accessory width as a share of the character height. Small on purpose: an accessory
## that reads as a blob is worse than none (DESIGN §4.5).
const SLOT_SIZES: Dictionary = {
	SLOT_HEAD: 0.34,
	SLOT_NECK: 0.26,
	SLOT_EYES: 0.22,
}
const ACCESSORY_ROOT: String = "res://assets/art/items/"

const Z_BODY: int = 0
const Z_OUTFIT: int = 10
const Z_EXPRESSION: int = 20
const Z_HEADWEAR: int = 30
const Z_NECK: int = 40
const Z_GLASSES: int = 50
const DEFAULT_ART_ASPECT: float = 1.0
## The scrub region (ADR-004 mode 2): a polygon around her body, derived from the
## opaque rect on every layout pass so it lands on the character at any aspect
## (T-E04-01). Authored in rig-local space; `scrub_hull_global` transforms it.
const SCRUB_HULL_POINTS: int = 12
const SCRUB_HULL_INSET: float = 12.0
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
## slot -> id, mirroring `SaveData.equipped_outfits`.
var accessory_ids: Dictionary = {}
var manual_step: bool = false
var seed_value: int = 20261104
var taps: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spring: SquashSpring = SquashSpring.new()
var _time: float = 0.0
var _next_blink_at: float = 0.0
var _blink_until: float = -1.0
var _face_before_anticipation: String = ""
var _opaque: Dictionary = {}
var _scrub_hull_local: PackedVector2Array = PackedVector2Array()


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
	if is_equal_approx(anchor_left, 0.5) and is_equal_approx(anchor_right, 0.5):
		var seen: Rect2 = opaque_rect(expression.texture) if expression != null else Rect2()
		var wanted: float = size.y * (seen.size.x / seen.size.y if seen.has_area() else DEFAULT_ART_ASPECT)
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
	var is_left_click: bool = (
		event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	)
	if (is_left_click or event is InputEventScreenTouch) and bool(event.get("pressed")):
		if _hits_character(event.get("position") as Vector2):
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
	if _blink_until >= 0.0 and _time >= _blink_until:
		_blink_until = -1.0
		if expression_id == BLINK_EXPRESSION:
			_apply_expression(NEUTRAL_EXPRESSION)
	elif _blink_until < 0.0 and _time >= _next_blink_at:
		if expression_id == NEUTRAL_EXPRESSION:
			_apply_expression(BLINK_EXPRESSION)
			_blink_until = _time + BLINK_HOLD_SEC
		_next_blink_at = _time + _rng.randf_range(BLINK_MIN_SEC, BLINK_MAX_SEC)
	if _spring.is_running():
		_spring.advance(step)
		if pivot != null:
			pivot.scale = _spring.scale


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


## Equips an accessory in its slot. One item per slot: the previous one is replaced,
## never stacked, so the character stays readable (T-E05-05).
func set_accessory(slot: String, id: String) -> bool:
	var sprite: Sprite2D = _accessory_sprite(slot)
	if sprite == null:
		LogSink.emit_from(self, "rig.invalid_slot", {"slot": "invalid"})
		return false
	if id.is_empty():
		sprite.visible = false
		sprite.texture = null
		accessory_ids.erase(slot)
		LogSink.emit_from(self, "rig.accessory_off", {"slot": slot})
		return true
	if not Ids.is_valid(id):
		LogSink.emit_from(self, "rig.invalid_accessory", {"slot": slot, "accessory": "invalid"})
		return false
	var texture: Texture2D = _load_accessory_art(id)
	if texture == null:
		LogSink.emit_from(self, "rig.missing_art", {"accessory": id})
		return false
	sprite.texture = texture
	sprite.visible = true
	accessory_ids[slot] = id
	_place_accessory(sprite, slot)
	LogSink.emit_from(self, "rig.accessory_on", {"slot": slot, "accessory": id})
	return true


func accessory_id(slot: String) -> String:
	return str(accessory_ids.get(slot, ""))


func clear_accessories() -> void:
	for slot: String in [SLOT_HEAD, SLOT_NECK, SLOT_EYES]:
		set_accessory(slot, "")


## An accessory is placed relative to the **mouth zone**, not at a fixed height: the
## mouth is a drag target (e03) and the face is the feedback channel (T-E05-06), so
## every slot is offset by its own art height plus a margin. That makes "does not
## cover the mouth" true by construction instead of by tuning.
func _place_accessory(sprite: Sprite2D, slot: String) -> void:
	if sprite == null or sprite.texture == null or mouth_zone == null:
		return
	var character: float = size.y if size.y > 1.0 else 620.0
	var art: Vector2 = sprite.texture.get_size()
	var factor: float = character * float(SLOT_SIZES.get(slot, 0.3)) / maxf(art.x, 1.0)
	var half_height: float = art.y * factor * 0.5
	var mouth_from_feet: float = size.y - mouth_zone.position.y
	var height: float = mouth_from_feet
	match slot:
		SLOT_EYES:
			height = mouth_from_feet + half_height + character * 0.02
		SLOT_HEAD:
			height = mouth_from_feet + half_height + character * 0.06
		SLOT_NECK:
			height = mouth_from_feet - half_height - character * 0.02
		_:
			height = mouth_from_feet
	sprite.scale = Vector2.ONE * factor
	sprite.position = Vector2(0.0, -height)


func _accessory_sprite(slot: String) -> Sprite2D:
	match slot:
		SLOT_HEAD:
			return headwear
		SLOT_NECK:
			return neck
		SLOT_EYES:
			return glasses
		_:
			return null


func _load_accessory_art(id: String) -> Texture2D:
	var path: String = "%s%s.png" % [ACCESSORY_ROOT, id]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func set_outfit(id: String) -> bool:
	if id.is_empty():
		_take_outfit_off()
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


func _take_outfit_off() -> void:
	if outfit != null:
		outfit.visible = false
		outfit.texture = null
	outfit_id = ""
	outfit_changed.emit("")


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


func mouth_global_center() -> Vector2:
	return global_position if mouth_zone == null else mouth_zone.get_global_rect().get_center()


func update_food_proximity(global_point: Vector2) -> void:
	if global_point.distance_to(mouth_global_center()) >= MOUTH_ANTICIPATION_PX:
		clear_food_proximity()
	elif _face_before_anticipation.is_empty():
		_face_before_anticipation = NEUTRAL_EXPRESSION if expression_id == BLINK_EXPRESSION else expression_id
		set_expression(ANTICIPATION_EXPRESSION)


func clear_food_proximity() -> void:
	var face: String = _face_before_anticipation
	_face_before_anticipation = ""
	if not face.is_empty() and expression_id == ANTICIPATION_EXPRESSION:
		set_expression(face)


func reset() -> void:
	_face_before_anticipation = ""
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
	var factor: float = (size.y if size.y > 1.0 else seen.y) / seen.y if seen.y > 0.0 else 1.0
	var shift: Vector2 = (art - used.size) * Vector2(0.5, 1.0) - used.position if used.has_area() else Vector2.ZERO
	for sprite: Sprite2D in [body, outfit, expression, headwear, neck, glasses]:
		if sprite != null:
			sprite.scale = Vector2.ONE * factor
			sprite.position = (Vector2(0.0, -art.y * 0.5) + shift) * factor
	_rebuild_scrub_hull(get_visual_global_rect())
	if mouth_zone != null:
		mouth_zone.size = seen * factor * 0.18
		mouth_zone.position = Vector2(size.x * 0.5 - mouth_zone.size.x * 0.5, size.y - seen.y * factor * 0.62)


## The scrub hull in rig-local coordinates: an ellipse inscribed in the visible
## art, inset by `SCRUB_HULL_INSET`, so a scrub registers on her body rather than
## on the transparent margin around it.
func scrub_hull_local() -> PackedVector2Array:
	return _scrub_hull_local


## The same polygon in global coordinates, transformed at call time, so a hull can
## never be stale after a resize (T-E04-01).
func scrub_hull_global() -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var to_canvas: Transform2D = get_global_transform_with_canvas()
	for point: Vector2 in _scrub_hull_local:
		out.append(to_canvas * point)
	return out


func _rebuild_scrub_hull(seen_global: Rect2) -> void:
	var origin: Vector2 = get_global_rect().position
	var box: Rect2 = Rect2(seen_global.position - origin, seen_global.size).grow(-SCRUB_HULL_INSET)
	if box.size.x <= 1.0 or box.size.y <= 1.0:
		_scrub_hull_local = PackedVector2Array()
		return
	var centre: Vector2 = box.get_center()
	var radii: Vector2 = box.size * 0.5
	var hull: PackedVector2Array = PackedVector2Array()
	for index: int in range(SCRUB_HULL_POINTS):
		var angle: float = TAU * float(index) / float(SCRUB_HULL_POINTS)
		hull.append(centre + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	_scrub_hull_local = hull


func _load_art(id: String) -> Texture2D:
	var path: String = "%squiqui_%s.png" % [ART_ROOT, id]
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
