# story: e13s05
class_name CareWalk
extends RefCounted
## Walks the care loop to CELEBRATE the way a child does, so the reward is earned and not faked.


static func to_celebrate(loop: Node) -> void:
	loop.call("begin_step", "FEED")
	for step_id: String in ["FEED", "BATH", "DRESS", "PLAY", "SLEEP"]:
		loop.call("complete_step", step_id)
