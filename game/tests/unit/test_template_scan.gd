# story: e13s09
extends GutTest
## Review round 3 (B6). No template or primitive holds an ad, a life, a shake or a weapon, and the scan can fail:
## the same checker flags a string that does.

const VERBS: PackedStringArray = [
	"video",
	"reward_ad",
	"rewarded",
	"admob",
	"advert",
	"watch_ad",
	"lives",
	"life_lost",
	"decreaselife",
	"shake",
	"bullet",
	"projectile",
	"game_over",
]


func test_no_template_or_primitive_has_an_ad_a_life_a_shake_or_a_weapon() -> void:
	var paths: Array[String] = _sources()
	assert_gt(paths.size(), 15, "the scan reads every template and primitive")
	for path: String in paths:
		assert_eq(_found(SourceScanner.text(path)), [], "SC-e13s05-P2-01 SC-e13s08-P1-01 %s" % path)


func test_the_scan_flags_what_it_names() -> void:
	assert_eq(_found("func go() -> void:\n\tshow_video()\n"), ["video"], "B6 control: an ad verb is caught")
	assert_eq(_found("var lives: int = 3"), ["lives"], "B6 control: a life counter is caught")
	assert_eq(_found("ScreenShake.play()"), ["shake"], "B6 control: a shake is caught, whatever the case")
	assert_eq(_found("var tap_count: int = 0"), [], "an honest file is clean")


func _found(body: String) -> Array[String]:
	var lowered: String = body.to_lower()
	var hits: Array[String] = []
	for verb: String in VERBS:
		if lowered.contains(verb):
			hits.append(verb)
	return hits


func _sources() -> Array[String]:
	var found: Array[String] = []
	for path: String in SourceScanner.scripts():
		var name: String = path.get_file()
		var component: bool = name.ends_with("primitive.gd") or name == "spawner.gd"
		if path.contains("/scripts/templates/") or (path.contains("/scripts/components/") and component):
			found.append(path)
	return found
