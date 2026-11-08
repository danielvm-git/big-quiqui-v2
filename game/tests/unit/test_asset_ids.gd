# story: e12s01
extends GutTest

const ART_ROOT: String = "res://assets/art/"
const AUDIO_ROOT: String = "res://assets/audio/"
const ID_NAME_RE: String = "\\A[a-z0-9_]+\\.(png|jpg|ogg)\\z"
const FORBIDDEN_DIR: Array[String] = ["amigos", "moveis", "efeitos", "estilo"]


func test_every_art_filename_matches_snake_case_grammar() -> void:
	var bad: Array[String] = []
	_walk(ART_ROOT, bad, [".png", ".jpg"])
	assert_eq(bad.size(), 0, "bad art names: %s" % str(bad))


func test_every_audio_filename_matches_snake_case_grammar() -> void:
	var bad: Array[String] = []
	_walk(AUDIO_ROOT, bad, [".ogg"])
	assert_eq(bad.size(), 0, "bad audio names: %s" % str(bad))


func test_no_portuguese_asset_directories_remain() -> void:
	for name: String in FORBIDDEN_DIR:
		var path: String = "%s%s" % [ART_ROOT, name]
		assert_false(DirAccess.dir_exists_absolute(path), "dir still exists: %s" % path)


func test_every_imported_media_has_an_import_sidecar() -> void:
	var missing: Array[String] = []
	_collect_missing_import(ART_ROOT, missing)
	_collect_missing_import(AUDIO_ROOT, missing)
	assert_eq(missing.size(), 0, "missing import: %s" % str(missing))


func _walk(root: String, bad: Array[String], suffixes: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		bad.append("missing root %s" % root)
		return
	_dir_walk(dir, root, bad, suffixes)


func _dir_walk(dir: DirAccess, path: String, bad: Array[String], suffixes: Array[String]) -> void:
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	var re: RegEx = RegEx.new()
	re.compile(ID_NAME_RE)
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var full: String = "%s%s" % [path, entry]
		if dir.current_is_dir():
			var sub: DirAccess = DirAccess.open(full)
			if sub != null:
				_dir_walk(sub, "%s/" % full, bad, suffixes)
		else:
			for suf: String in suffixes:
				if entry.ends_with(suf) and re.search(entry) == null:
					bad.append(full)
					break
		entry = dir.get_next()
	dir.list_dir_end()


func _collect_missing_import(root: String, missing: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		return
	_import_walk(dir, root, missing)


func _import_walk(dir: DirAccess, path: String, missing: Array[String]) -> void:
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var full: String = "%s%s" % [path, entry]
		if dir.current_is_dir():
			var sub: DirAccess = DirAccess.open(full)
			if sub != null:
				_import_walk(sub, "%s/" % full, missing)
		elif entry.ends_with(".png") or entry.ends_with(".jpg") or entry.ends_with(".ogg"):
			var imp: String = "%s.import" % full
			if not FileAccess.file_exists(imp):
				missing.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
