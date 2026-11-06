# story: e06s01
class_name GardenProp
extends Control
## A garden toy: tapped, it moves for a bounded time and then rests (T-E06-04).
##
## The motion is deliberately *not* a state machine — it is a closed-form animation of
## a single `_elapsed` value, because a prop has no legal edges to protect. What it
## does own is the rest state: `is_idle()` is true only when the animation is over, so
## a scene can assert calm (abandon, scene exit) instead of guessing.

signal interacted(interaction: String)

enum Kind { BOUNCE, SPIN, SQUEEZE }

## How long one interaction lasts, per kind. Bounded by design: a toy that never
## settles is a screen a child cannot leave calmly.
const BOUNCE_SEC: float = 1.1
const SPIN_SEC: float = 1.3
const SQUEEZE_SEC: float = 0.5
const BOUNCE_HEIGHT: float = 48.0
const BOUNCE_HOPS: float = 3.0
const SPIN_TURNS: float = 2.0
const SQUEEZE_SCALE: float = 0.86

var kind: Kind = Kind.BOUNCE
## Interaction id this prop reports; the scene completes PLAY on three *distinct* ids
## (T-E06-05), so the id is part of the contract, not a log decoration.
var interaction: String = "ball"

var _elapsed: float = -1.0
var _rest_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rest_position = position


func _gui_input(event: InputEvent) -> void:
	if event.device == -1:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		trigger()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		trigger()


## Starts the motion. A second tap while moving re-aims the animation from the
## current frame instead of stacking: play stays responsive without drifting.
func trigger() -> bool:
	if not is_inside_tree():
		return false
	_elapsed = 0.0
	_apply(0.0)
	interacted.emit(interaction)
	return true


func advance(delta: float) -> void:
	if _elapsed < 0.0:
		return
	_elapsed += maxf(delta, 0.0)
	if _elapsed >= _duration():
		reset_prop()
		return
	_apply(_elapsed)


func is_idle() -> bool:
	return _elapsed < 0.0


func reset_prop() -> void:
	_elapsed = -1.0
	position = _rest_position
	rotation = 0.0
	scale = Vector2.ONE


func _duration() -> float:
	match kind:
		Kind.SPIN:
			return SPIN_SEC
		Kind.SQUEEZE:
			return SQUEEZE_SEC
		_:
			return BOUNCE_SEC


func _apply(elapsed: float) -> void:
	var progress: float = clampf(elapsed / _duration(), 0.0, 1.0)
	match kind:
		Kind.SPIN:
			rotation = TAU * SPIN_TURNS * progress
		Kind.SQUEEZE:
			var squeeze: float = 1.0 - (1.0 - SQUEEZE_SCALE) * sin(PI * progress)
			scale = Vector2(squeeze, squeeze)
		_:
			var hop: float = absf(sin(PI * progress * BOUNCE_HOPS)) * BOUNCE_HEIGHT
			position = _rest_position - Vector2(0.0, hop * (1.0 - progress))
