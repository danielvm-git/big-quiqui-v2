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

const _VOICE_KEYS: Dictionary = {
	"pato": "vo.duck.intro",
	"urso": "vo.bear.intro",
	"pinguim": "vo.penguin.intro",
}


static func is_friend(id: String) -> bool:
	return FRIEND_IDS.has(id)


const _ART: Dictionary = {
	"pato": "duck",
	"urso": "bear",
	"pinguim": "penguin",
}


static func art_path(id: String) -> String:
	if not is_friend(id):
		return ""
	var file: String = str(_ART.get(id, id))
	return "res://assets/art/friends/%s.png" % file


static func scene_path(id: String) -> String:
	return str(_SCENES.get(id, ""))


static func voice_key(id: String) -> String:
	return str(_VOICE_KEYS.get(id, ""))


static func voice_path(id: String) -> String:
	var key: String = voice_key(id)
	if key.is_empty():
		return ""
	return AudioManager.voice_path_for_key(key)


## FIX-05: minigame payouts are tuning data in `EconomyData`. A missing or negative
## entry pays 0 — never a negative mint.
static func coins_of(id: String, economy: EconomyData) -> int:
	if economy == null:
		return 0
	return maxi(int(economy.minigame_coins.get(id, 0)), 0)
