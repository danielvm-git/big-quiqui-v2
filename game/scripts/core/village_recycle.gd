# story: e14s05
class_name VillageRecycle
extends RefCounted
## One recycle payout per village visit — the same rule the legacy Vila held.

static var recycled_this_session: bool = false


static func reset_session() -> void:
	recycled_this_session = false
