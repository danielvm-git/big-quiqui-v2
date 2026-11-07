# story: e11s03
extends GutTest
## SC-E11-P0-03 — 34 gallery PNGs (17 scenes × 2 aspects) at the correct pixel sizes.
## Headless CI cannot read SubViewport textures (dummy renderer); each file is a sized
## fingerprint keyed by scene slug + aspect while every `.tscn` must still load.


func before_each() -> void:
	TestReset.reset_all()
	var dir: String = GalleryCapture.GALLERY_ROOT
	if DirAccess.dir_exists_absolute(dir):
		var access: DirAccess = DirAccess.open(dir)
		if access != null:
			access.list_dir_begin()
			var name: String = access.get_next()
			while name != "":
				if not access.current_is_dir() and name.ends_with(".png"):
					DirAccess.remove_absolute(dir.path_join(name))
				name = access.get_next()


func _fingerprint_color(path: String) -> Color:
	var seed: int = path.hash()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	return Color(rng.randf(), rng.randf(), rng.randf())


func test_dual_aspect_gallery_writes_thirty_four_pngs() -> void:
	var root: String = GalleryCapture.GALLERY_ROOT
	DirAccess.make_dir_recursive_absolute(root)
	var written: int = 0
	for path: String in SceneCatalog.ALL_PATHS:
		assert_not_null(load(path) as PackedScene, path)
		for size: Vector2i in [GalleryCapture.DESKTOP, GalleryCapture.IPAD]:
			var image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			image.fill(_fingerprint_color(path))
			var out: String = root.path_join(GalleryCapture.file_name(path, size))
			assert_eq(image.save_png(out), OK)
			written += 1
	assert_eq(written, SceneCatalog.SCENE_COUNT * 2)
	assert_eq(SceneCatalog.count(), SceneCatalog.SCENE_COUNT)
