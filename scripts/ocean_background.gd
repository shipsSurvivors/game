extends Sprite2D

# Texture pixels scrolled per second.
@export var drift_speed := Vector2(4.0, 2.0)

var scroll_offset := Vector2.ZERO


func _process(delta: float) -> void:
	if texture == null:
		return

	# Move the texture slowly, independently of frame rate.
	scroll_offset += drift_speed * delta

	# Wrap after one tile so the values stay small.
	scroll_offset.x = fposmod(scroll_offset.x, texture.get_width())
	scroll_offset.y = fposmod(scroll_offset.y, texture.get_height())

	# Shift the sampled texture while keeping the ocean in place.
	var region := region_rect
	region.position = scroll_offset
	region_rect = region
