extends Control

signal retry_pressed
signal title_pressed

# Load the scenes we need for the buttons.
const GAME_SCENE := preload("res://scenes/player/gameplay.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title_screen.tscn")

# Find the buttons after this scene's nodes are ready.
@onready var retry_button: Button = $CenterContainer/VBoxContainer/RetryButton
@onready var title_button: Button = $CenterContainer/VBoxContainer/TitleButton


func _ready() -> void:
	# Run our functions whenever the buttons are pressed.
	retry_button.pressed.connect(_on_retry_pressed)
	title_button.pressed.connect(_on_title_pressed)

	# Select Retry so Enter or Space can activate it.
	retry_button.grab_focus()


func _on_retry_pressed() -> void:
	# Tell the GameManager that Retry was selected.
	retry_pressed.emit()


func _on_title_pressed() -> void:
	title_pressed.emit()
