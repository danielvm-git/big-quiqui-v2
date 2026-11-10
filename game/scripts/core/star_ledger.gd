# story: e10s01
class_name StarLedger
extends RefCounted
## The friend-star half of the save, extracted from `ProgressManager`. Pure functions over `SaveData`:
## they validate and mutate, but never save and never emit. A refusal comes back as the diary line to write.


## `{}` when a star was added, else `{"data": ...}` for `star.refused`. Every refusal happens before the
## first mutation, so a replayed win can never double-pay and an unsafe id never reaches the save.
static func add(data: SaveData, friend_id: String) -> Dictionary:
	if data == null or not FriendCatalog.is_friend(friend_id):
		return {"friend": "invalid"}
	var current: int = of(data, friend_id)
	if current >= SaveData.MAX_STARS:
		return {"friend": friend_id, "reason": "cap"}
	data.friend_stars[friend_id] = current + 1
	return {}


## The clamped read side: a tampered save shows what the rules allow, never more.
static func of(data: SaveData, friend_id: String) -> int:
	if data == null or not data.friend_stars.has(friend_id):
		return 0
	return clampi(int(data.friend_stars[friend_id]), 0, SaveData.MAX_STARS)
