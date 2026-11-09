# story: e12s01
class_name VoicePlayback
extends RefCounted
## Type-gate-safe voice start: scenes cannot use the AudioManager autoload global
## during GDScript.reload(); resolve the autoload by path at runtime instead.


static func play_key(from: Node, key: String) -> bool:
	var manager: Node = from.get_node_or_null("/root/AudioManager")
	if manager == null:
		return false
	return bool(manager.call("play_voice_key", key))
