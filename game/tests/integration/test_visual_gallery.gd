# story: e11s03
extends GutTest
## SC-E11-P0-03 — every shipped scene passes GeometryOracle on both aspects and writes
## a 34-file gallery manifest under `user://gallery/` (headless-safe fingerprints).

var scene: Control = null


func before_each() -> void:
	TestReset.reset_all()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _oracle_spec(path: String) -> Dictionary:
	if path.ends_with("titulo.tscn"):
		return GeometryOracle.TITLE_SPEC
	return GeometryOracle.STEP_ROOM_SPEC


func _mount(path: String, size: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(path) as PackedScene
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


func test_seventeen_scenes_pass_oracle_on_both_aspects_and_write_gallery_manifest() -> void:
	var root: String = GalleryCapture.GALLERY_ROOT
	DirAccess.make_dir_recursive_absolute(root)
	var written: int = 0
	for path: String in SceneCatalog.ALL_PATHS:
		for size: Vector2i in [GalleryCapture.DESKTOP, GalleryCapture.IPAD]:
			scene = _mount(path, size)
			scene.set("manual_step", true)
			await wait_process_frames(2)
			var oracle: GeometryOracle = GeometryOracle.new()
			var findings: Array[String] = oracle.audit(scene, size, _oracle_spec(path))
			assert_true(findings.is_empty(), "%s %s: %s" % [path, size, oracle.summary()])
			var image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			image.fill(Color.from_hsv(float(path.hash() % 360) / 360.0, 0.35, 0.85))
			var out: String = root.path_join(GalleryCapture.file_name(path, size))
			assert_eq(image.save_png(out), OK)
			written += 1
			scene.queue_free()
			scene = null
	assert_eq(written, SceneCatalog.SCENE_COUNT * 2)
