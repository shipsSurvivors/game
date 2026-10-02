extends HBoxContainer

# Reuse the same artist-made digits as the clock.
const DIGITS = [
	preload("res://sprites/n0.png"),
	preload("res://sprites/n1.png"),
	preload("res://sprites/n2.png"),
	preload("res://sprites/n3.png"),
	preload("res://sprites/n4.png"),
	preload("res://sprites/n5.png"),
	preload("res://sprites/n6.png"),
	preload("res://sprites/n7.png"),
	preload("res://sprites/n8.png"),
	preload("res://sprites/n9.png")
]

var last_level: int = -1


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 0)

	set_number(1)


func set_number(value: int) -> void:
	# Rebuild only when the level changes.
	if value == last_level:
		return

	last_level = value

	for child in get_children():
		remove_child(child)
		child.queue_free()

	# Supports levels 1, 10, 100, and beyond.
	for character in str(value):
		var digit := TextureRect.new()
		digit.texture = DIGITS[int(character)]
		digit.custom_minimum_size = Vector2(24, 34)
		digit.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		digit.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		digit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(digit)
