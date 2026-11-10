# story: e13s09
class_name PrizeLedger
extends RefCounted
## The wheel's one pick per care cycle. The pick is kept with the cycle it was made in, so the next
## cycle opens a fresh wheel. Pure functions over `SaveData`: they validate and mutate, never save.
## The cycle is `completed_cycles`, which `CareLoopManager` raises when it pays at CELEBRATE, so the wheel
## belongs after that pay. Reaching it earlier would let one cycle take two picks.


## True when the pick was recorded. A second pick in the same cycle, or an unsafe id, changes nothing.
static func pick(data: SaveData, id: String) -> bool:
	if data == null or not Ids.is_valid(id) or not current(data).is_empty():
		return false
	data.picked_prize = id
	data.prize_cycle = data.completed_cycles
	return true


## The prize picked in the cycle the child is in now, or "".
static func current(data: SaveData) -> String:
	if data == null or data.picked_prize.is_empty() or data.prize_cycle != data.completed_cycles:
		return ""
	return data.picked_prize
