extends HBoxContainer

# Artist's numbers, ordered from zero through nine.
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

var last_second: int = -1


func _ready() -> void:
	# Keep the number artwork crisp.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)

	# Anchor the clock to the top-center of the screen.
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)

	# Place a 180-pixel-wide clock around that center point.
	offset_left = -90.0
	offset_right = 90.0
	offset_top = 20.0
	offset_bottom = 64.0

	alignment = BoxContainer.ALIGNMENT_CENTER

	set_time(0.0)


func set_time(elapsed: float) -> void:
	var total_seconds := int(elapsed)

	# Rebuild only when the displayed second changes.
	if total_seconds == last_second:
		return

	last_second = total_seconds

	var minutes := int(total_seconds / 60.0)
	var seconds := total_seconds % 60
	var clock_text := "%02d:%02d" % [minutes, seconds]

	# Remove the previous displayed digits.
	for child in get_children():
		remove_child(child)
		child.queue_free()

	for character in clock_text:
		if character == ":":
			# Use a text colon between the artist's digits.
			var separator := Label.new()
			separator.text = ":"
			separator.custom_minimum_size = Vector2(14, 44)
			separator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			separator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			separator.add_theme_font_size_override("font_size", 32)
			separator.add_theme_color_override(
				"font_color", Color("#d5a62e")
			)
			separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(separator)
		else:
			var digit := TextureRect.new()
			digit.texture = DIGITS[int(character)]
			digit.custom_minimum_size = Vector2(32, 44)
			digit.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			digit.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			digit.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(digit)
