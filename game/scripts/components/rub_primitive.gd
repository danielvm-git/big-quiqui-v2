# story: e13s01
class_name RubPrimitive
extends RefCounted
## Covered-area ratio on top of ScrubGesture. The runner owns completion.

const CELL_EDGE: int = 4
const MODES: PackedStringArray = ["clear", "leave", "reveal"]
const EDGE_MIN: int = 2
const EDGE_MAX: int = 12

## Cells per side of the measuring grid. Finer cells need a more even rub. The def sets it.
var edge: int = CELL_EDGE

var _gesture: ScrubGesture = ScrubGesture.new()
var _marked: Dictionary = {}


func _init() -> void:
	_gesture.lazy_start = true


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


## Teardown: silence and free the loop node the gesture put on the host.
func release_all() -> void:
	_gesture.stop()
	_gesture.release_loop()


## Only cells whose centre is inside the hull count, in the numerator and the denominator alike.
func progress() -> float:
	var area: Dictionary = _area_cells()
	if area.is_empty():
		return 0.0
	var covered: int = 0
	for key: String in _marked.keys():
		if area.has(key):
			covered += 1
	return clampf(float(covered) / float(area.size()), 0.0, 1.0)


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
	var span: Vector2 = box.size / float(edge)
	var col: int = clampi(int((point.x - box.position.x) / span.x), 0, edge - 1)
	var row: int = clampi(int((point.y - box.position.y) / span.y), 0, edge - 1)
	return "%d:%d" % [col, row]


func _area_cells() -> Dictionary:
	var box: Rect2 = _bbox()
	var cells: Dictionary = {}
	if box.size.x <= 1.0 or box.size.y <= 1.0:
		return cells
	var hull: PackedVector2Array = _gesture.hull_points()
	var step: Vector2 = box.size / float(edge)
	for col: int in range(edge):
		for row: int in range(edge):
			var centre: Vector2 = box.position + Vector2((float(col) + 0.5) * step.x, (float(row) + 0.5) * step.y)
			if Geometry2D.is_point_in_polygon(centre, hull):
				cells["%d:%d" % [col, row]] = true
	return cells
