# story: e10s01
class_name FriendCatalog
extends RefCounted
## The friend table every minigame reads (e10s01): one owner for the ids and the
## id -> art/scene/voice mapping, so no scene hardcodes a path. The intro voice
## lines were recorded with english names; that mismatch lives here and nowhere
## else.

const FRIEND_IDS: Array[String] = ["pato", "urso", "pinguim"]

const _SCENES: Dictionary = {
	"pato": "res://scenes/pato_danca.tscn",
	"urso": "res://scenes/urso_puzzle.tscn",
	"pinguim": "res://scenes/pinguim_jogo.tscn",
}

const _VOICES: Dictionary = {
	"pato": "res://assets/audio/voice/duck_intro.ogg",
	"urso": "res://assets/audio/voice/bear_intro.ogg",
	"pinguim": "res://assets/audio/voice/penguin_intro.ogg",
}


static func is_friend(id: String) -> bool:
	return FRIEND_IDS.has(id)


static func art_path(id: String) -> String:
	return "res://assets/art/amigos/%s.png" % id if is_friend(id) else ""


static func scene_path(id: String) -> String:
	return str(_SCENES.get(id, ""))


static func voice_path(id: String) -> String:
	return str(_VOICES.get(id, ""))


## FIX-05: minigame payouts are tuning data in `EconomyData`. A missing or negative
## entry pays 0 — never a negative mint.
static func coins_of(id: String, economy: EconomyData) -> int:
	if economy == null:
		return 0
	return maxi(int(economy.minigame_coins.get(id, 0)), 0)
