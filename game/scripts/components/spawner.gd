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


func tick() -> void:
	_age()
	_tick += 1
	if items.is_empty() or cadence <= 0 or _tick % cadence != 0:
		return
	var item: String = items[_rng.randi() % items.size()]
	var lane: int = _rng.randi() % maxi(lane_count, 1)
	_live.append({"item": item, "lane": lane, "born": _tick})
	_log.append("%s:%d" % [item, lane])


func take_lane(lane: int) -> int:
	var kept: Array[Dictionary] = []
	var taken: int = 0
	for row: Dictionary in _live:
		if int(row.get("lane", -1)) == lane:
			taken += 1
		else:
			kept.append(row)
	_live = kept
	return taken


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


func _age() -> void:
	var kept: Array[Dictionary] = []
	for row: Dictionary in _live:
		var born: int = int(row.get("born", 0))
		if _tick - born >= lifetime:
			_misses += 1
		else:
			kept.append(row)
	_live = kept
