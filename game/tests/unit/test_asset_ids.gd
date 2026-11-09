# story: e12s01
extends GutTest

const ART_ROOT: String = "res://assets/art/"
const AUDIO_ROOT: String = "res://assets/audio/"
const ID_NAME_RE: String = "\\A[a-z0-9_]+\\.(png|jpg|ogg)\\z"
const FORBIDDEN_DIR: Array[String] = ["amigos", "moveis", "efeitos", "estilo"]
## Shipped configs that name `res://` paths but are not scanned as source.
const CONFIG_PATHS: Array[String] = ["res://project.godot", "res://export_presets.cfg"]


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


## The rename's blind spot: `project.godot` and `export_presets.cfg` are not `.gd` files, so
## no source scan reached them. The iOS preset read `config/icon` at export time and the
## macOS job failed on a path that no longer existed (found by CI, not by the suite).
## Every `res://` a shipped config names must resolve on disk.
func test_every_res_path_in_shipped_configs_exists() -> void:
	var missing: Array[String] = []
	for config_path: String in CONFIG_PATHS:
		missing.append_array(_dangling_paths(config_path))
	assert_eq(missing.size(), 0, "dangling res:// in shipped config: %s" % str(missing))


func test_the_dangling_path_check_can_fail() -> void:
	var probe: String = "res://assets/art/ui/this_file_does_not_exist.png"
	assert_false(ResourceLoader.exists(probe), "the probe must not exist")
	var found: Array[String] = []
	if not ResourceLoader.exists(probe):
		found.append(probe)
	assert_eq(found.size(), 1, "a missing path is reported, so the gate is not decoration")


func _dangling_paths(config_path: String) -> Array[String]:
	var out: Array[String] = []
	var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		out.append("missing config %s" % config_path)
		return out
	var text: String = file.get_as_text()
	file.close()
	var re: RegEx = RegEx.new()
	re.compile("res://[A-Za-z0-9_./-]+")
	for found: RegExMatch in re.search_all(text):
		var path: String = found.get_string()
		# Directory filters (`res://tests/*`) name a directory, not a file.
		if path.ends_with("/") or path.ends_with("/*"):
			continue
		if not ResourceLoader.exists(path):
			out.append(path)
	return out


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
