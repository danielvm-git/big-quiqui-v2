# story: e13s01
class_name RubPrimitive
extends RefCounted
## Covered-area ratio on top of ScrubGesture. The runner owns completion.

const CELL_EDGE: int = 4

var mode: String = "reveal"

var _gesture: ScrubGesture = ScrubGesture.new()
var _marked: Dictionary = {}


func bind_target(target: Control) -> void:
	_gesture.target = target
	_marked.clear()


func set_loop(stream: AudioStream) -> void:
	_gesture.loop_stream = stream


func begin(host: Node) -> void:
	_gesture.begin(host)


func rub_at(point: Vector2) -> bool:
	if not _gesture.consume(point):
		return false
	var key: String = _cell_key(point)
	if key.is_empty():
		return false
	_marked[key] = true
	return true


func release() -> void:
	_gesture.stop()


func progress() -> float:
	var area: int = _area_count()
	if area <= 0:
		return 0.0
	return clampf(float(_marked.size()) / float(area), 0.0, 1.0)


func claims_completion() -> bool:
	return false


func playing_channels() -> int:
	return 1 if _gesture.is_playing() else 0


func owned_channels() -> int:
	return _gesture.loop_player_count()


func _bbox() -> Rect2:
	var hull: PackedVector2Array = _gesture.hull_points()
	if hull.size() < 3:
		return Rect2()
	var min_p: Vector2 = hull[0]
	var max_p: Vector2 = hull[0]
	for point: Vector2 in hull:
		min_p.x = minf(min_p.x, point.x)
		min_p.y = minf(min_p.y, point.y)
		max_p.x = maxf(max_p.x, point.x)
		max_p.y = maxf(max_p.y, point.y)
	return Rect2(min_p, max_p - min_p)


func _cell_key(point: Vector2) -> String:
	var box: Rect2 = _bbox()
	if box.size.x <= 1.0 or box.size.y <= 1.0:
		return ""
	var span: Vector2 = box.size / float(CELL_EDGE)
	var col: int = clampi(int((point.x - box.position.x) / span.x), 0, CELL_EDGE - 1)
	var row: int = clampi(int((point.y - box.position.y) / span.y), 0, CELL_EDGE - 1)
	return "%d:%d" % [col, row]


func _area_count() -> int:
	var box: Rect2 = _bbox()
	if box.size.x <= 1.0 or box.size.y <= 1.0:
		return 0
	var total: int = 0
	var hull: PackedVector2Array = _gesture.hull_points()
	for col: int in range(CELL_EDGE):
		total += _row_hits(box, hull, col)
	return total


func _row_hits(box: Rect2, hull: PackedVector2Array, col: int) -> int:
	var hits: int = 0
	var step: Vector2 = box.size / float(CELL_EDGE)
	for row: int in range(CELL_EDGE):
		var centre: Vector2 = box.position + Vector2((float(col) + 0.5) * step.x, (float(row) + 0.5) * step.y)
		if Geometry2D.is_point_in_polygon(centre, hull):
			hits += 1
	return hits
