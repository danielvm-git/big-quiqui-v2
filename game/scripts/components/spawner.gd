# story: e13s08
class_name Spawner
extends RefCounted
## Seeded items on a cadence. Stop leaves nothing behind. No wall clock.

var rng_seed: int = 1
var items: PackedStringArray = PackedStringArray()
var cadence: int = 2
var lifetime: int = 4
var lane_count: int = 1

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _tick: int = 0
var _live: Array[Dictionary] = []
var _log: PackedStringArray = PackedStringArray()
var _misses: int = 0


func start() -> void:
	_rng.seed = rng_seed
	_tick = 0
	_live.clear()
	_log = PackedStringArray()
	_misses = 0


## One step of time. A row that has fallen the whole way is caught when the basket is in its lane
## and leaves quietly when it is not. Returns how many were caught on this tick.
func tick(basket_lane: int = -1) -> int:
	var caught: int = _age(basket_lane)
	_tick += 1
	if items.is_empty() or cadence <= 0 or _tick % cadence != 0:
		return caught
	var item: String = items[_rng.randi() % items.size()]
	var lane: int = _rng.randi() % maxi(lane_count, 1)
	_live.append({"item": item, "lane": lane, "born": _tick})
	_log.append("%s:%d" % [item, lane])
	return caught


## Copies of the live rows with their age in ticks, so a template can draw them.
func live_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row: Dictionary in _live:
		var copy: Dictionary = row.duplicate()
		copy["age"] = _tick - int(row.get("born", 0))
		rows.append(copy)
	return rows


func misses() -> int:
	return _misses


func first_lane() -> int:
	if _live.is_empty():
		return -1
	return int(_live[0].get("lane", -1))


func live_count() -> int:
	return _live.size()


func sequence() -> PackedStringArray:
	return _log


func stop() -> void:
	_live.clear()


func _age(basket_lane: int) -> int:
	var kept: Array[Dictionary] = []
	var caught: int = 0
	for row: Dictionary in _live:
		if _tick - int(row.get("born", 0)) < lifetime:
			kept.append(row)
		elif int(row.get("lane", -1)) == basket_lane:
			caught += 1
		else:
			_misses += 1
	_live = kept
	return caught
