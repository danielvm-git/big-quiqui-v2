# story: e12s01
class_name VoiceKeyResolver
extends RefCounted

const VOICE_KEY_PREFIX: String = "vo."
const VOICE_ROOT: String = "res://assets/audio/voice/"
const VOICE_LOCALES: Array[String] = ["pt_BR"]


static func path_for_key(key: String, locale: String = "pt_BR") -> String:
	if not key.begins_with(VOICE_KEY_PREFIX):
		return ""
	var tail: String = key.substr(VOICE_KEY_PREFIX.length())
	if tail.is_empty():
		return ""
	var parts: PackedStringArray = tail.split(".")
	if parts.is_empty():
		return ""
	for part: String in parts:
		if not Ids.is_valid(part):
			return ""
	if not VOICE_LOCALES.has(locale):
		return ""
	var file: String = "_".join(parts) + ".ogg"
	return "%s%s/%s" % [VOICE_ROOT, locale, file]
