# story: e01s04
class_name QuiQuiRig
extends Control
## Layered character rig (ADR-003): a `Control` box owns the layout, an inner
## foot-pivoted `Node2D` owns the art, so breathing/scaling never moves the feet
## and never fights the anchors.
##
## Layer order is fixed by DESIGN §4.5 — an outfit must never hide the face:
##   Body(0) → Outfit(10) → Expression(20) → Headwear(30) → Neck(40) → Glasses(50)
##
## Everything is stepped by `advance(delta)` so tests are deterministic; the
## blink interval is the only randomness and it comes from an injectable RNG.

const ART_ROOT: String = "res://assets/art/quiqui/"
const ID_PATTERN: String = "^[a-z0-9_]{2,32}$"

const NEUTRAL_EXPRESSION: String = "base"
const BLINK_EXPRESSION: String = "pisca"

## DESIGN §4.1/§4.2
const BREATH_PERIOD_SEC: float = 2.2
const BREATH_X: float = 0.018
const BREATH_Y: float = 0.022
const BLINK_MIN_SEC: float = 2.8
const BLINK_MAX_SEC: float = 5.2
const BLINK_HOLD_SEC: float = 0.130

## DESIGN §4.4 — same spring as TapButton.
const SQUASH_STEPS: Array[Vector2] = [Vector2(1.14, 0.88), Vector2(0.94, 1.07), Vector2.ONE]
const SQUASH_STEP_SEC: Array[float] = [0.07, 0.09, 0.11]

const Z_BODY: int = 0
const Z_OUTFIT: int = 10
const Z_EXPRESSION: int = 20
const Z_HEADWEAR: int = 30
const Z_NECK: int = 40
const Z_GLASSES: int = 50

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
var _time: float = 0.0
var _next_blink_at: float = 0.0
var _blink_until: float = -1.0
var _squash_step: int = -1
var _squash_elapsed: float = 0.0
var _id_re: RegEx = RegEx.new()


func _ready() -> void:
	_id_re.compile(ID_PATTERN)
	_rng.seed = seed_value
	_reset_blink_schedule()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_rig()
	set_expression(NEUTRAL_EXPRESSION)


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
	if pivot == null:
		return
	var wave: float = sin(_time * BREATH_PERIOD_SEC)
	var breathing: Vector2 = Vector2(1.0 - BREATH_X * wave, 1.0 + BREATH_Y * wave)
	if _squash_step >= 0:
		return  # the tap spring owns the transform while it runs
	pivot.scale = breathing


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
	var remaining: float = delta
	while _squash_step >= 0 and remaining > 0.0:
		var limit: float = SQUASH_STEP_SEC[_squash_step]
		if _squash_elapsed + remaining < limit:
			_squash_elapsed += remaining
			remaining = 0.0
			break
		remaining -= limit - _squash_elapsed
		_squash_elapsed = 0.0
		_squash_step += 1
		if _squash_step >= SQUASH_STEPS.size():
			_squash_step = -1
			if pivot != null:
				pivot.scale = Vector2.ONE
			break
		if pivot != null:
			pivot.scale = SQUASH_STEPS[_squash_step]


# ── public API ───────────────────────────────────────────────────────────────


func play_squash() -> void:
	_squash_step = 0
	_squash_elapsed = 0.0
	if pivot != null:
		pivot.scale = SQUASH_STEPS[0]


func is_squashing() -> bool:
	return _squash_step >= 0


func is_blinking() -> bool:
	return _blink_until >= 0.0


## Returns false and keeps the current art when the id does not exist.
func set_expression(id: String) -> bool:
	if not _valid_id(id):
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
		outfit_id = ""
		outfit_changed.emit("")
		return true
	if not _valid_id(id):
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
	_squash_step = -1
	outfit_id = ""
	_rng.seed = seed_value
	_reset_blink_schedule()
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
	if texture == null:
		return
	expression.texture = texture
	expression.visible = true
	expression_id = id
	_update_layout()
	expression_changed.emit(id)


## Feet-anchored layout: the art is drawn upward from the pivot, and the visual
## stack is sized against the control box.
func _update_layout() -> void:
	if expression.texture == null:
		return
	var art: Vector2 = expression.texture.get_size()
	var box: Vector2 = size if size.x > 1.0 else art
	var factor: float = minf(box.x / art.x, box.y / art.y) if art.x > 0.0 and art.y > 0.0 else 1.0
	for sprite: Sprite2D in [body, outfit, expression, headwear, neck, glasses]:
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


func _valid_id(id: String) -> bool:
	if id.is_empty() or id.length() > 32:
		return false
	return _id_re.search(id) != null


func _tap() -> void:
	taps += 1
	play_squash()
	tapped.emit()
	_emit("rig.tap", {"expression": expression_id})


func _emit(ev: String, data: Dictionary) -> void:
	var sink: Node = get_node_or_null("/root/Log")
	if sink != null and sink.has_method("event"):
		sink.call("event", ev, data)
