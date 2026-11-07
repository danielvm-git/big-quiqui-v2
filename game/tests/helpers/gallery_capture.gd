# story: e11s03
class_name GalleryCapture
extends RefCounted
## Headless dual-aspect PNG capture for the release gallery gate.

const GALLERY_ROOT: String = "user://gallery/"
const DESKTOP: Vector2i = GeometryOracle.DESKTOP_16_9
const IPAD: Vector2i = GeometryOracle.IPAD_4_3


static func aspect_tag(size: Vector2i) -> String:
	if size == IPAD:
		return "4x3"
	return "16x9"


static func file_name(scene_path: String, size: Vector2i) -> String:
	var slug: String = scene_path.get_file().get_basename()
	return "%s_%s.png" % [slug, aspect_tag(size)]


static func mount_scene(path: String, size: Vector2i, viewport_host: Node) -> SubViewport:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_host.add_child(viewport)
	var packed: PackedScene = load(path) as PackedScene
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	if instance is Control:
		(instance as Control).set("manual_step", true)
	RenderingServer.force_draw(true)
	return viewport


static func grab_image(viewport: SubViewport) -> Image:
	var tex: ViewportTexture = viewport.get_texture()
	if tex == null:
		return Image.create(viewport.size.x, viewport.size.y, false, Image.FORMAT_RGBA8)
	var image: Image = tex.get_image()
	if image == null:
		return Image.create(viewport.size.x, viewport.size.y, false, Image.FORMAT_RGBA8)
	return image


static func teardown(viewport: SubViewport) -> void:
	if viewport == null or not is_instance_valid(viewport):
		return
	var parent: Node = viewport.get_parent()
	if parent != null:
		parent.remove_child(viewport)
	viewport.queue_free()
