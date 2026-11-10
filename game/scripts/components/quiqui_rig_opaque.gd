# story: e01s04
class_name QuiQuiRigOpaque
extends RefCounted
## Opaque-pixel bounds for rig sprites. Cached per texture instance id.


static func union_sprite_rect(sprites: Array, cache: Dictionary) -> Rect2:
	var rect: Rect2 = Rect2()
	var started: bool = false
	for sprite: Sprite2D in sprites:
		if sprite == null or not sprite.visible or sprite.texture == null:
			continue
		var used: Rect2 = used_pixels(sprite.texture, cache)
		if not used.has_area():
			continue
		var top_left: Vector2 = sprite.global_position - sprite.texture.get_size() * 0.5 * sprite.global_scale
		var sprite_rect: Rect2 = Rect2(top_left + used.position * sprite.global_scale, used.size * sprite.global_scale)
		rect = sprite_rect if not started else rect.merge(sprite_rect)
		started = true
	return rect


static func used_pixels(texture: Texture2D, cache: Dictionary) -> Rect2:
	if texture == null:
		return Rect2()
	var key: int = texture.get_instance_id()
	if cache.has(key):
		return cache[key] as Rect2
	var used: Rect2 = Rect2()
	var image: Image = texture.get_image()
	if image != null and not image.is_empty():
		var opaque: Rect2i = image.get_used_rect()
		if opaque.size.x > 0 and opaque.size.y > 0:
			used = Rect2(Vector2(opaque.position), Vector2(opaque.size))
	if not used.has_area():
		LogSink.emit_to_diary("rig.opaque_unreadable", {"art": texture.resource_path.get_file()})
	cache[key] = used
	return used
