# story: e01s04
class_name QuiQuiRig
extends Control
## Layered character rig (ADR-003): `Control` layout box + foot-pivoted `Node2D` art stack.

const ART_ROOT: String = "res://assets/art/quiqui/"
const NEUTRAL_EXPRESSION: String = "base"
const BLINK_EXPRESSION: String = "wink"
const MOUTH_ANTICIPATION_PX: float = 220.0
const ANTICIPATION_EXPRESSION: String = "mouth_open"
const BREATH_PERIOD_SEC: float = 2.2
const BREATH_X: float = 0.018
const BREATH_Y: float = 0.022
const BLINK_MIN_SEC: float = 2.8
const BLINK_MAX_SEC: float = 5.2
const BLINK_HOLD_SEC: float = 0.130
## Accessory slots live in `AccessorySlots` (vocabulary + placement maths); the rig
## owns only the layers and the art loading.
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
var _accessories: QuiQuiRigAccessory = null


func _ready() -> void:
	_accessories = QuiQuiRigAccessory.new(self)
	_rng.seed = seed_value
	_next_blink_at = _rng.randf_range(BLINK_MIN_SEC, BLINK_MAX_SEC)
	mouse_filter = Control.MOUSE_FILTER_STOP
	QuiQuiRigBuild.assemble(self)
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
	return _accessories.set_slot(slot, id)


func accessory_id(slot: String) -> String:
	return _accessories.id_for(slot)


func clear_accessories() -> void:
	_accessories.clear_all()


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
	return QuiQuiRigOpaque.union_sprite_rect([body, outfit, expression, headwear, neck, glasses] as Array, _opaque)


## Opaque box in frame pixels, cached by `get_instance_id()` (logs once per unreadable texture).
func opaque_rect(texture: Texture2D) -> Rect2:
	return QuiQuiRigOpaque.used_pixels(texture, _opaque)


func mouth_global_center() -> Vector2:
	return QuiQuiRigMouth.global_center(self)


func update_food_proximity(global_point: Vector2) -> void:
	QuiQuiRigMouth.update_food_proximity(self, global_point)


func clear_food_proximity() -> void:
	QuiQuiRigMouth.clear_food_proximity(self)


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
	QuiQuiRigLayout.update(self)


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
	_scrub_hull_local = QuiQuiScrubHull.local_polygon(
		seen_global, get_global_rect(), SCRUB_HULL_POINTS, SCRUB_HULL_INSET
	)


func _load_art(id: String) -> Texture2D:
	var path: String = "%squiqui_%s.png" % [ART_ROOT, id]
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
