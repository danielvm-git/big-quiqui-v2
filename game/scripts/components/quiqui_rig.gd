# story: e01s04
class_name QuiQuiRig
extends Control
## Layered character rig (ADR-003): a `Control` box owns the layout, an inner
## foot-pivoted `Node2D` owns the art, so breathing/scaling never moves the feet
## and never fights the anchors (ADR-008 re-anchors the pivot on resize).
##
## Layer order is fixed by DESIGN §4.5 — an outfit must never hide the face:
## Body(0) → Outfit(10) → Expression(20) → Headwear(30) → Neck(40) → Glasses(50).
## The accessory layers are the ADR-003 contract (art lands in e10).
##
## Stepped by `advance(delta)` so tests are deterministic; the blink interval is
## the only randomness and it comes from an injectable RNG.

const ART_ROOT: String = "res://assets/art/quiqui/"

const NEUTRAL_EXPRESSION: String = "base"
const BLINK_EXPRESSION: String = "pisca"

## DESIGN §4.1/§4.2
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

## The art is square (1024x1024). The box is fitted to this aspect on resize so
## the *painted* character keeps DESIGN §3's 55-65 % on every canvas instead of
## the box keeping it while the art shrinks (BUG-013).
const DEFAULT_ART_ASPECT: float = 1.0
## A box that keeps this much canvas height above the art is a taller frame than
## the character: `GeometryOracle` fails it (BUG-013).
const BOX_FIT_EPSILON: float = 0.5

## Legacy composition: these are full-body images, so only one may be visible at
## a time until e10 ships separate body/outfit/expression layers.
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
var _art_aspect: float = DEFAULT_ART_ASPECT


func _ready() -> void:
	_rng.seed = seed_value
	_reset_blink_schedule()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_rig()
	set_expression(NEUTRAL_EXPRESSION)
	_refit()  # the first layout pass can land before the pivot exists


## The responsive layout, in one place: fit the box to the art, re-anchor the
## feet on the bottom edge, re-fit the sprites. Safe to call any number of times.
func _refit() -> void:
	if pivot == null:
		return
	_fit_box_to_art()
	pivot.position = Vector2(size.x * 0.5, size.y)
	_update_layout()


## A responsive box (ADR-008) may be laid out after `_ready`: fit the box to the
## art and re-anchor instead of keeping the first frame's geometry.
func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	_refit()


## The builder's ratio anchors own the **height**; the width has to follow the
## art, or `_update_layout`'s width-limited fit shrinks the character on taller
## canvases (BUG-013). Only valid for the centred 0.5/0.5 anchor column every
## builder pins — symmetric offsets then keep her centred at any width.
func _fit_box_to_art() -> void:
	if not is_equal_approx(anchor_left, anchor_right) or not is_equal_approx(anchor_left, 0.5):
		return
	var wanted: float = size.y * _art_aspect
	if wanted <= 1.0 or absf(size.x - wanted) < BOX_FIT_EPSILON:
		return
	offset_left = -wanted * 0.5
	offset_right = wanted * 0.5


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		if (event as InputEventMouse).device == -1:
			return
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_tap()
		return
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_tap()


# ── stepping ─────────────────────────────────────────────────────────────────


func advance(delta: float) -> void:
	var step: float = maxf(delta, 0.0)
	_time += step
	_apply_breathing()
	_advance_blink()
	_advance_squash(step)


func _apply_breathing() -> void:
	if pivot == null or _spring.is_running():
		return  # the tap spring owns the transform while it runs
	var wave: float = sin(_time * BREATH_PERIOD_SEC)
	pivot.scale = Vector2(1.0 - BREATH_X * wave, 1.0 + BREATH_Y * wave)


func _advance_blink() -> void:
	if _blink_until >= 0.0:
		if _time >= _blink_until:
			_blink_until = -1.0
			if expression_id == BLINK_EXPRESSION:
				_apply_expression(NEUTRAL_EXPRESSION)
		return
	if _time < _next_blink_at:
		return
	# Only a neutral face blinks; an active expression must not be overwritten.
	if expression_id == NEUTRAL_EXPRESSION:
		_apply_expression(BLINK_EXPRESSION)
		_blink_until = _time + BLINK_HOLD_SEC
	_reset_blink_schedule()


func _reset_blink_schedule() -> void:
	_next_blink_at = _time + _rng.randf_range(BLINK_MIN_SEC, BLINK_MAX_SEC)


func _advance_squash(delta: float) -> void:
	if not _spring.is_running():
		return
	_spring.advance(delta)
	if pivot != null:
		pivot.scale = _spring.scale


# ── public API ───────────────────────────────────────────────────────────────


func play_squash() -> void:
	_spring.start()
	if pivot != null:
		pivot.scale = _spring.scale


func is_squashing() -> bool:
	return _spring.is_running()


func is_blinking() -> bool:
	return _blink_until >= 0.0


## Returns false and keeps the current art when the id does not exist.
func set_expression(id: String) -> bool:
	if not Ids.is_valid(id):
		_emit("rig.invalid_expression", {"expression": "invalid"})
		return false
	if id == expression_id and expression != null:
		return true
	var texture: Texture2D = _load_art(id)
	if texture == null:
		_emit("rig.missing_art", {"expression": id})
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
		_emit("rig.invalid_outfit", {"outfit": "invalid"})
		return false
	var texture: Texture2D = _load_art(id)
	if texture == null:
		_emit("rig.missing_art", {"outfit": id})
		return false
	outfit.texture = texture
	outfit.visible = true
	outfit_id = id
	outfit_changed.emit(id)
	return true


## The union of every visible sprite, in rig-local coordinates. The mouth zone and
## the scrub hull must live inside this rect (TEST_PLAN §1.4).
func get_visual_global_rect() -> Rect2:
	var rect: Rect2 = Rect2()
	var started: bool = false
	for sprite: Sprite2D in [body, outfit, expression, headwear, neck, glasses]:
		if sprite == null or not sprite.visible or sprite.texture == null:
			continue
		var sprite_rect: Rect2 = Rect2(
			sprite.global_position - sprite.texture.get_size() * 0.5 * sprite.global_scale,
			sprite.texture.get_size() * sprite.global_scale,
		)
		rect = sprite_rect if not started else rect.merge(sprite_rect)
		started = true
	return rect


func reset() -> void:
	taps = 0
	_time = 0.0
	_blink_until = -1.0
	_spring.stop()
	_rng.seed = seed_value
	_reset_blink_schedule()
	set_outfit("")  # the outfit layer is owned by set_outfit, never by a flag
	if pivot != null:
		pivot.scale = Vector2.ONE
	set_expression(NEUTRAL_EXPRESSION)


# ── construction ─────────────────────────────────────────────────────────────


func _build_rig() -> void:
	pivot = Node2D.new()
	pivot.name = "Pivot"
	pivot.position = Vector2(size.x * 0.5, size.y)  # feet anchor
	add_child(pivot)

	body = _make_sprite("Body", Z_BODY)
	outfit = _make_sprite("Outfit", Z_OUTFIT)
	expression = _make_sprite("Expression", Z_EXPRESSION)
	headwear = _make_sprite("Headwear", Z_HEADWEAR)
	neck = _make_sprite("Neck", Z_NECK)
	glasses = _make_sprite("Glasses", Z_GLASSES)
	outfit.visible = false
	headwear.visible = false
	neck.visible = false
	glasses.visible = false

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
	_fit_box_to_art()
	_update_layout()
	expression_changed.emit(id)


## Feet-anchored layout: the art is drawn upward from the pivot, and the visual
## stack is fitted to the control box. `_fit_box_to_art` keeps the box art-shaped,
## so the fit is height-driven and the painted height equals the box height.
func _update_layout() -> void:
	if expression == null or expression.texture == null:
		return
	var art: Vector2 = expression.texture.get_size()
	if art.x > 0.0 and art.y > 0.0:
		_art_aspect = art.x / art.y
	var box: Vector2 = size if size.x > 1.0 else art
	var factor: float = minf(box.x / art.x, box.y / art.y) if art.x > 0.0 and art.y > 0.0 else 1.0
	for sprite: Sprite2D in [body, outfit, expression, headwear, neck, glasses]:
		if sprite == null:
			continue
		sprite.scale = Vector2.ONE * factor
		sprite.position = Vector2(0.0, -art.y * factor * 0.5)
	if mouth_zone != null:
		mouth_zone.size = art * factor * 0.18
		mouth_zone.position = Vector2(
			size.x * 0.5 - mouth_zone.size.x * 0.5,
			size.y - art.y * factor * 0.62,
		)


func _load_art(id: String) -> Texture2D:
	var path: String = "%squiqui_%s.png" % [ART_ROOT, id]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _tap() -> void:
	taps += 1
	play_squash()
	tapped.emit()
	_emit("rig.tap", {"expression": expression_id})


func _emit(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
