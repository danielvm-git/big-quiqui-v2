# story: e12s01
extends GutTest


func test_every_scene_voice_key_resolves() -> void:
	var keys: Array[String] = [
		"vo.kitchen.intro",
		"vo.closet.intro",
		"vo.bathroom.intro",
		"vo.home.welcome",
		"vo.duck.intro",
	]
	for key: String in keys:
		var path: String = AudioManager.voice_path_for_key(key)
		assert_false(path.is_empty(), key)
		assert_true(ResourceLoader.exists(path), path)
