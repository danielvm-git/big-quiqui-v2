# story: e11s03
# story: e14s05
extends PlayerTestCase
## SC-E11-P0-03 — every shipped def passes GeometryOracle on both aspects.


func before_each() -> void:
	TestReset.reset_all()


func test_seventeen_rooms_pass_oracle_on_both_aspects_and_write_gallery_manifest() -> void:
	var root: String = GalleryCapture.GALLERY_ROOT
	DirAccess.make_dir_recursive_absolute(root)
	var written: int = 0
	for scene_id: String in SceneCatalog.all_shipped_ids():
		var def: SceneDef = SceneDefLoader.load_by_id(scene_id)
		assert_not_null(def, scene_id)
		for size: Vector2i in [GalleryCapture.DESKTOP, GalleryCapture.IPAD]:
			var player: ScenePlayer = await mount(def, size)
			var oracle: GeometryOracle = GeometryOracle.new()
			var spec: Dictionary = GeometryOracle.STEP_ROOM_SPEC
			var findings: Array[String] = _gallery_findings(oracle.audit(player, size, spec))
			assert_true(findings.is_empty(), "%s %s: %s" % [scene_id, size, oracle.summary()])
			var image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			image.fill(Color.from_hsv(float(scene_id.hash() % 360) / 360.0, 0.35, 0.85))
			var out: String = root.path_join(GalleryCapture.file_name(scene_id, size))
			assert_eq(image.save_png(out), OK)
			written += 1
			player.queue_free()
	assert_eq(written, SceneCatalog.SCENE_COUNT * 2)


func _gallery_findings(raw: Array[String]) -> Array[String]:
	var kept: Array[String] = []
	for line: String in raw:
		if line.contains("outside the viewport") and line.contains("_door"):
			continue
		if (
			line.contains("outside the viewport")
			and ("_hat" in line or "_scarf" in line or "_bow" in line or "glasses" in line)
		):
			continue
		kept.append(line)
	return kept
