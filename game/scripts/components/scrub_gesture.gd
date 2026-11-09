# story: e03s01
class_name ScrubGesture
extends RefCounted
## The CONTINUOUS_SCRUB state of a drag (ADR-004 mode 2, T-E04-05): the finger moves
## and the prop does not, so this owns the hull test, the point count and the one SFX
## channel the gesture plays. A target that is missing, freed or not a hull means
## "no hull, no scrubs", never an error.

var target: Control = null
var loop_stream: AudioStream = null
var points: int = 0
## When true the loop waits for the first point inside the hull (a rub that misses is silent).
var lazy_start: bool = false

var _loop: ScrubLoop = null
var _host: Node = null


## Starts a gesture: the count resets and the loop (if any) plays on the host node.
func begin(host: Node) -> void:
	points = 0
	_host = host
	if not lazy_start:
		_start_loop()


func consume(point: Vector2) -> bool:
	var hull: PackedVector2Array = hull_points()
	if hull.size() < 3 or not Geometry2D.is_point_in_polygon(point, hull):
		return false
	points += 1
	if lazy_start and points == 1:
		_start_loop()
	return true


func stop() -> void:
	if _loop != null:
		_loop.stop()


## Frees the loop node the gesture put on its host. A later `begin` makes a fresh one.
func release_loop() -> void:
	if _loop != null and is_instance_valid(_loop):
		_loop.queue_free()
	_loop = null


func is_playing() -> bool:
	return _loop != null and _loop.is_playing()


func loop_player_count() -> int:
	return 0 if _loop == null else _loop.player_count()


## The target's hull, transformed at call time.
func hull_points() -> PackedVector2Array:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return PackedVector2Array()
	if not target.has_method("scrub_hull_global"):
		return PackedVector2Array()
	var hull: Variant = target.call("scrub_hull_global")
	return hull if hull is PackedVector2Array else PackedVector2Array()


func _start_loop() -> void:
	if loop_stream == null or _host == null or not is_instance_valid(_host):
		return
	if _loop == null:
		_loop = ScrubLoop.new()
		_loop.name = "ScrubLoop"
		_host.add_child(_loop)
	_loop.play_stream(loop_stream)
