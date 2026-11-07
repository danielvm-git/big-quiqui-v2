# story: e03s01
class_name ScrubLoop
extends Node
## The one SFX channel a CONTINUOUS_SCRUB gesture owns for the length of the gesture
## (T-E04-05). Extracted from `TouchDraggable` so the drag component stays one subject.

var _player: AudioStreamPlayer = null


func play_stream(stream: AudioStream) -> void:
	if stream == null:
		return
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "ScrubLoopPlayer"
		_player.bus = "SFX"
		add_child(_player)
	_player.stream = stream
	_player.play()


func stop() -> void:
	if _player != null and _player.playing:
		_player.stop()


func is_playing() -> bool:
	return _player != null and _player.playing


func player_count() -> int:
	return 0 if _player == null else 1
